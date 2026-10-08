# Sound streams

Writing a sound device with `device_sound_interface`, and routing it to speakers in machine configuration. mame-review rules that govern it: C-1 (stream updates in read handlers), C-8 (sound feature flags), D-2 (no `ATTR_COLD` on `sound_stream_update`), T-7 (per-sample hot path), F-3 (`speaker.h` goes in the .cpp).

## TL;DR

- Allocate the stream in `device_start` with `stream_alloc(inputs, outputs, rate)`. Implement `sound_stream_update(sound_stream &stream)` with `stream.samples()`, `stream.get(input, i)` and `stream.put*(output, i, ...)`.
- Call `m_stream->update()` before any write that changes what the stream will generate, and before a read that returns state the update advances; guard it in reads when the update raises IRQs or callbacks.
- To follow a clock change, call `m_stream->set_sample_rate()` from `device_clock_changed()`. It brings the stream up to date itself.
- Use one multi-channel speaker: `SPEAKER(config, "speaker", 2).front();` with `add_route(out, "speaker", gain, channel)`. Mono is `SPEAKER(config, "mono").front_center();`.
- A sound device needs only `emu.h`. Include `sound.h` only to call `machine().sound()`, and include `speaker.h` in the .cpp that declares `SPEAKER`.

## Rules

### Device declaration and update callback

**Do**

```cpp
// mysnd.h
class mysnd_device : public device_t, public device_sound_interface
{
public:
	static constexpr feature_type imperfect_features() { return feature::SOUND; }

	mysnd_device(const machine_config &mconfig, const char *tag, device_t *owner, u32 clock);
	void write(offs_t offset, u8 data);
	u8 status_r();

protected:
	// device_t implementation
	virtual void device_start() override ATTR_COLD;
	virtual void device_clock_changed() override;
	// device_sound_interface implementation
	virtual void sound_stream_update(sound_stream &stream) override;

private:
	sound_stream *m_stream;
	u16 m_period, m_counter;
	u8 m_volume;
	bool m_output;
};

// mysnd.cpp
void mysnd_device::device_start()
{
	m_stream = stream_alloc(0, 1, clock() / 64);   // inputs, outputs, sample rate
	m_period = 1; m_counter = 0; m_volume = 0; m_output = false;
	save_item(NAME(m_period)); save_item(NAME(m_counter));
	save_item(NAME(m_volume)); save_item(NAME(m_output));
}

void mysnd_device::sound_stream_update(sound_stream &stream)
{
	for (int i = 0; i < stream.samples(); i++)
	{
		if (++m_counter >= m_period) { m_counter = 0; m_output = !m_output; }
		stream.put_int(0, i, m_output ? m_volume : -m_volume, 16);   // value / 16 as float
	}
}
```

Output buffers arrive pre-cleared, so a silent or disabled chip can just return. Samples are `float` (`sound_stream::sample_t`) with a nominal range of ±1. Use `put_clamp`/`put_int_clamp` only where the hardware saturates. Use `add`/`add_int` to accumulate voices. A filter or mixer with inputs reads `stream.get(input, i)`, and `stream.copy(out, in)` passes audio through unchanged. Pass `STREAM_SYNCHRONOUS` as the fourth argument only for a DSP that must run one sample at a time, because it costs a timer per sample. Streams are created in `device_start` or `interface_pre_start` (docs §2.1). Inputs and outputs are numbered across all of a device's streams in the order they were allocated. `emu.h` provides `device_sound_interface` and `sound_stream`. Only a file that calls `machine().sound()` (for example `system_mute`) also includes `sound.h`. Older code relies on `emu.h` having included it.

**Legacy forms**: 2020-09 to 2025-04: `sound_stream_update(sound_stream &stream, std::vector<read_stream_view> const &inputs, std::vector<write_stream_view> &outputs)` with `auto &buffer = outputs[0]; buffer.put(i, v)`, `outputs[0].put_int(i, v, max)`, `inputs[0].get(i)`, an explicit `buffer.fill(0)` when silent, and `stream_buffer::sample_t` members. Before 2020-09: `sound_stream_update(sound_stream &, stream_sample_t **inputs, stream_sample_t **outputs, int samples)` and, briefly, `sound_stream_update_legacy`.
**Since**: `d0f1c15a0f6` (authored 2025-04-14, committed 2025-04-27, O. Galibert, "New sound infrastructure", converted 1092 files); views from `c1bd56f0d31` (2020-09-13); `stream_sample_t` removed `7b8913fefa4` (2020-09-27); `sound.h` dropped from `emu.h` and `sound_stream` moved to `disound.h` in `6deb9130b69` (2026-07-30, AJR)
**Evidence**: [T1] `src/emu/disound.h`: `virtual void sound_stream_update(sound_stream &stream) = 0;`, `stream_alloc(int inputs, int outputs, int sample_rate, sound_stream_flags flags = sound_stream_flags(0))`, `enum sound_stream_flags` (only `STREAM_DEFAULT_FLAGS`, `STREAM_SYNCHRONOUS`); [T1] the `src/emu/sound.h` header comment still describes `read_stream_view`/`write_stream_view`, which is stale; the declarations win; [T2] `device_sound_interface.rst` §2.1–2.2, §3.3 ("pre-cleared"; clamp only if the hardware does); [T2] mame-review D-2 (`sound_stream_update` is not `ATTR_COLD`), T-7 (no allocation, maps or `std::function` per sample), C-8 (declare `imperfect_features()`/`unemulated_features()` with `feature::SOUND`), D-3 (feature flags above the constructor); [T3] `6deb9130b69` added `#include "sound.h"` to `galaxian.cpp`, `xmen.cpp` and `discrete.cpp` for `machine().sound()`; [T5] deviation: `src/devices/bus/coco/coco_multi.cpp` marks `sound_stream_update` `ATTR_COLD`
**Key symbols**: `sound_stream_update`, `stream_alloc`, `sound_stream`, `samples`, `put`, `put_int`, `put_int_clamp`, `add_int`, `get`, `copy`, `STREAM_SYNCHRONOUS`, `SAMPLE_RATE_OUTPUT_ADAPTIVE`, `feature::SOUND`, `sound_manager`

### Bring the stream up to date before state changes

**Do**

```cpp
void mysnd_device::write(offs_t offset, u8 data)
{
	m_stream->update();   // render up to now with the old settings
	if (offset)
		m_volume = data & 0x0f;
	else
		m_period = std::max<u16>(data, 1);
}

u8 mysnd_device::status_r()
{
	m_stream->update();   // m_output is advanced by the update
	return m_output ? 0x80 : 0x00;
}
```

The stream renders only when something asks it to. Without the update, a register write applies to samples that should have been generated with the old value. Also update in any other hook that changes generator input, such as `rom_bank_pre_change()` for `device_rom_interface`. `update()` does nothing while an update is already running, so calling it from a callback the update itself invokes is harmless. In reads, C-1 asks that the debugger still see the real value. When the update only renders samples and advances the generator, catching up now produces the same samples as catching up later, so the update can stay unguarded. When `sound_stream_update` has effects outside the stream — raising an IRQ, firing a callback, setting status a CPU acknowledges — guard the update with `!machine().side_effects_disabled()` (flagged as C-1 on `sa16.cpp` in #16356). Anything else the read changes goes under the guard too.

**Legacy forms**: none distinct. Older code sometimes omits the update and is simply wrong.
**Since**: established
**Evidence**: [T1] `src/emu/sound.h` header comment ("sound chips and CPU-driven devices ... should force any affected streams to update prior to making changes"); [T1] `sound_stream::update()` in `src/emu/disound.cpp` returns early on `m_in_update`; [T2] mame-review C-1; [T4] #16356 (C-1 on `sa16.cpp`: unconditional `m_stream->update()` in reads reaches `raise_env_event()`; guard it); [T5] in `src/devices/sound` read handlers, 59 call `m_stream->update()` unguarded (`okim6295.cpp`, `ics2115.cpp`) and 13 put it under `!side_effects_disabled()` (`l6009.cpp`, `hc55516.cpp`)
**Key symbols**: `update`, `rom_bank_pre_change`, `side_effects_disabled`

### Sample-rate changes

**Do**

```cpp
void mysnd_device::device_clock_changed()
{
	m_stream->set_sample_rate(clock() / 64);
}
```

`device_clock_changed()` runs only after `device_start` (and again from `post_load` when the clock changed), so `m_stream` is valid. `set_sample_rate` calls `update()` itself, resamples the buffer, and saves the new rate in the stream's own state. It must not be called from inside `sound_stream_update`, which is a `fatalerror`. It also clears adaptive mode. For a pass-through filter or volume chip whose rate follows its target, allocate with `SAMPLE_RATE_OUTPUT_ADAPTIVE`, or `SAMPLE_RATE_INPUT_ADAPTIVE` to follow the source.

**Legacy forms**: `m_stream->update();` immediately before `set_sample_rate` (redundant, harmless); `stream_alloc(..., machine().sample_rate())` (34 on master), which ties the stream to the host output rate rather than the hardware.
**Since**: `SAMPLE_RATE_ADAPTIVE` and the internal update in `set_sample_rate` arrived with `d0f1c15a0f6` (2025-04-14); the input and output adaptive constants are older
**Evidence**: [T1] `src/emu/disound.cpp` `sound_stream::internal_set_sample_rate` (update, resample, `fatalerror` while `m_samples_to_update > 0`); [T1] `src/emu/device.cpp` `set_unscaled_clock` notifies only `if (m_started)`; [T2] `device_sound_interface.rst` §2.1, §3.6
**Key symbols**: `set_sample_rate`, `device_clock_changed`, `SAMPLE_RATE_INPUT_ADAPTIVE`, `SAMPLE_RATE_OUTPUT_ADAPTIVE`, `SAMPLE_RATE_ADAPTIVE`

### Routing and speakers

**Do**

```cpp
#include "speaker.h"   // in the driver .cpp (F-3)
	SPEAKER(config, "speaker", 2).front();          // channel 0 = FL, 1 = FR
	MYSND(config, m_snd, 4_MHz_XTAL)
		.add_route(0, "speaker", 0.50, 0)
		.add_route(0, "speaker", 0.50, 1);          // mono chip to both sides
	m_opm->add_route(0, "speaker", 0.60, 0);        // stereo chip
	m_opm->add_route(1, "speaker", 0.60, 1);
	SPEAKER(config, "mono").front_center();
	m_dac->add_route(ALL_OUTPUTS, "mono", 0.25);
```

`add_route(output, target, gain, channel)` takes the source output, the target as a tag, finder or interface, a gain, and the target's input channel. `ALL_OUTPUTS` sends every output to that one channel. Speaker positions are set per channel with `front_left(ch)`, `front_right(ch)`, `front_center(ch)`, `rear_*`, `headrest_*`, `backrest`, `lfe`, `unknown` and `map_on_request_only`, or as groups with `front()`, `rear()` and `corners()`. A slot or bus connector that only relays audio derives from `device_mixer_interface`. It allocates one stream per routed channel itself and needs no update code. Drivers don't set user gains, which belong to the UI sliders (docs §2.4).

**Legacy forms**: separate mono speakers `SPEAKER(config, "lspeaker").front_left(); SPEAKER(config, "rspeaker").front_right();` routed with `add_route(0, "lspeaker", 1.0)`; `add_route(..., AUTO_ALLOC_INPUT, mixoutput)`; `front_floor()`, `seat()`; `device_mixer_interface(mconfig, *this, outputs)`.
**Since**: multi-channel speakers in `d0f1c15a0f6` (2025-04-14); `lfe`, `unknown`, `map_on_request_only` and `osd::channel_position` in `1050ddce5bc`/`f0e6df80480` (2025-05/06), which also dropped `front_floor` and `seat`
**Evidence**: [T1] `src/emu/speaker.h` `sound_io_device` position helpers and the `speaker_device(..., u32 channels = 1)` constructor; [T1] `src/emu/disound.h` `add_route(u32 output, ..., double gain, u32 channel = 0)`; [T2] `device_sound_interface.rst` §2.5, §4; [T5] master has 567 files with `SPEAKER(config, "speaker", 2)` against 3 with `"lspeaker"`; deviation: `src/mame/apple/psc.cpp` and `src/mame/bfm/bfm_cobra3.cpp`, both added in the last year, use `lspeaker`/`rspeaker`
**Key symbols**: `SPEAKER`, `speaker_device`, `add_route`, `ALL_OUTPUTS`, `front`, `front_center`, `device_mixer_interface`

## Superseded

- `STREAM_DISABLE_INPUT_RESAMPLING`, `SAMPLE_RATE_INVALID`, `SAMPLE_RATE_MINIMUM`, `AUTO_ALLOC_INPUT`: removed in `d0f1c15a0f6` (inputs are always resampled). The view and `stream_sample_t` signatures are under **Legacy forms**.

## Examples

- `src/devices/sound/cf61909.cpp` @ `d0f1c15a0f6`: an output-only PCM chip with `stream_alloc(0, 1, clock() / CLOCKS_PER_SAMPLE)`, `set_sample_rate` in `device_clock_changed`, `update()` before register writes and in `rom_bank_pre_change`, and `put_int_clamp` for a 10-bit DAC. Written by Devin Acker and converted to the current API by O. Galibert.
- `src/devices/sound/tda7433.cpp` @ `4a83bce04f3`: a 4-in/4-out volume chip with `SAMPLE_RATE_OUTPUT_ADAPTIVE` and `stream.get`/`stream.put` per channel, calling `update()` only when a register value changes (R. Belmont). Deviations: its log lines use `tag()` instead of `describe_context()` (L-1), and it has an empty `device_reset`.
