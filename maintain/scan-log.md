# Scan log

One line per candidate: `<hash> <verdict> <topic or -> <reason>`; one per mame-review rule change: `mame-review <ID> <changed|added|removed> <topics or ->`. Newest batch at the bottom, under a heading naming the range and date.

## Review comments, initial harvest 2026-09-29 → 2026-10-08 (2026-10-08)

Superseded the same day: the mame-review rules are public (rb6502/mame-ai-tips `442b673`), so the inferred code catalog and comment harvesting were dropped. Kept as a record of which rules were being enforced on PRs.

#16187 review C-1,C-3,C-11,D-1,D-2,D-3,D-7,D-8,D-10,D-11,F-3,L-1,L-4,T-5 logging
#16342 review C-1,C-3,C-9,C-11,D-3,D-5,F-4,L-3,T-6 -
#16343 review C-2,C-5,C-8,C-11,D-6,D-12,F-3,F-6,L-3,L-4,T-3,T-4,T-5,X-1 -
#16326 review C-1,C-2,C-3,C-5,C-8,C-11,D-1,D-2,D-5,D-12,F-3,I-3,I-4,I-5,L-3,S-2,T-1,T-3,T-6,X-1 -
#16299 review C-1,C-3,C-5,C-7,C-8,C-11,D-2,D-3,D-4,D-5,D-10,F-3,F-4,F-6,L-1,L-3,L-4,T-2 logging
#16299 reply (mamehaze) defers three Tidy items post-merge — Tidy is negotiable
#16356 review C-1,C-2,C-5,C-8,C-11,D-2,D-3,D-4,D-7,F-3,F-6,L-3,T-1,T-2,X-1 -
#16346 review T-6 -
#16352 review C-1,C-3,D-2,D-11 -
#16324 review C-2,C-8,C-11,D-5,D-6,F-3,F-4,F-5,F-6,I-1,I-5,L-3,N-1,O-1,T-4,T-6,X-1,X-2 -
#16313 review C-1,C-2,C-4,C-5,C-9,C-10,C-11,D-3,D-7,D-8,D-10,D-11,F-1,F-2,I-1,I-5 -
#16346 reply (clawgrip) quote only

## History sweep 2023-10-07 → ab1bc044b6d (2026-10-08)

Candidates: `core` and `deprecated` tags only (638). Mechanical prefilter removed 391 commits touching no driver-facing core file (only `.cpp` internals, or debug/render/layout/audio_effects/chd/cdrom/xtal/validity/options files) and with neither `deprecated` nor `mass` tag; logged as `noise (prefilter)`. The remaining 247 were triaged by reading diffs.

### Prefiltered

c662f2ec6bc noise - (prefilter) render.cpp: Nuke previous scaler when releasing a render_texture in ca
6f1abb62220 noise - (prefilter) emu/romload.cpp: Removed apparently obsolete FIXME comment.
e5c4907791f noise - (prefilter) Disallow zero-length regions in ROM definitions and software lists
901a68e2e0b noise - (prefilter) chd.cpp, chdcodec.cpp: Minor refactoring - Return std::error_condition
cc772072fa6 noise - (prefilter) chd.cpp: Refactoring, part 2 - Change is_XXX to return std::error_cond
4587e86e869 noise - (prefilter) Revert "chd.cpp: Refactoring, part 2"
de955af966f noise - (prefilter) Revert "chd.cpp, chdcodec.cpp: Minor refactoring"
e4ceeee5674 noise - (prefilter) Added some additional layout functionality and script bindings.
79bef1e2304 noise - (prefilter) 3rdparty/lzma: Updated to version 23.01.
c7f9676add6 noise - (prefilter) emu/rendlay.cpp: Keep alpha channel intact when drawing text component
25b2829babd noise - (prefilter) -emu/ioport.cpp: Allow punching holes in IPT_UNUSED and IPT_UNKNOWN.
c4eff71c34d noise - (prefilter) sound: removed cfg defvol/newvol (was already deprecated)
3c1320f4b1f noise - (prefilter) nubus/nubus_cb264.cpp, pds30_cb264.cpp: Better guess at screen paramet
b9fbc6e7e96 noise - (prefilter) formats/flacfile.cpp: Added support for compact cassette images in FLA
642c89bd148 noise - (prefilter) rendersw: add out of bounds check to 16-bit get_texel (32-bit version 
9c951445f5b noise - (prefilter) lib/util/flac.cpp: Add support for flac data where bits_per_sample != 
2802da16495 noise - (prefilter) mm2: update notes about turbokit, chess*: small tweaks
194e5cd77fb noise - (prefilter) New systems marked not working ------------------------------ Cuty Lin
2251902b445 noise - (prefilter) brke23p2: change rom filename to same as set name, rendlay: let's make
b75b8d80e87 noise - (prefilter) util/cdrom.cpp: Don't strip pregaps from Redump GD-ROM files (#11913)
4c0957d7f0b noise - (prefilter) lib/util/cdrom.h: fix out-of-bounds MAME init crash when disc is 99 tr
e4d6dc1be9c noise - (prefilter) imagedev/cdromimg.cpp: Fixed object lifecycles when loading from softl
44d45a6342c noise - (prefilter) util/cdrom.h: Fixed size of track info array.
a83d26b101d noise - (prefilter) emu/memarray.cpp: Fix little Endian byte read/write to 64-bit areas. (
c43a83bbdcd noise - (prefilter) Miscellaneous cleanups:
a62fa6efc50 noise - (prefilter) util/cdrom.cpp: Removed unreachable additional handler for MODE2/2336 
d88e1271430 noise - (prefilter) ui: move decrease frameskip key from F8 to Shift F9
57314928745 noise - (prefilter) tools/chdman.cpp: Fixed numerous issues, including:
a1e5795e34b noise - (prefilter) nvram: delete file on save if there's a write error or result file is 
c0d7a5c6076 noise - (prefilter) Revert "ui: move decrease frameskip key from F8 to Shift F9"
2995e59d506 noise - (prefilter) ui: add quick save/load state shortcut, default key undecided
f4acecb4534 noise - (prefilter) imagedev/floppy.cpp: Delete unused getter that leaked details
45890ad85c6 noise - (prefilter) Default UI keys cleanup [hap, R. Belmont] - Pause moved from P to F5 -
f8345b810de noise - (prefilter) Fixed OSD interaction with updated default keys. [R. Belmont]
d64e3f7cf25 noise - (prefilter) util/chd.cpp: Calculate size of buffer needed to store hunk map (fixes
acf19127484 noise - (prefilter) - osd sdl default keys: remove ctrl-blocks on f3 and f4, move opengl f
b5abcac1417 noise - (prefilter) -osd/mac, osd/sdl: Show prescale popup when it hasn't changed due to h
a3c19ba0ac5 noise - (prefilter) machine: add filename to save/load state message
827aa3d02bf noise - (prefilter) machine: reword save/loadstate popmessage a bit again
8b33ac0d0d8 noise - (prefilter) Merge branch 'release0263' into HEAD
853db181d2c noise - (prefilter) util/cdrom.cpp: Refactored parse_cue and parse_gdicue (should fix GitH
1c40f545189 noise - (prefilter) diserial: increase start delay from 0.25 to 0.33 cycle
a94b5f35d3f noise - (prefilter) New systems marked not working ------------------------------ Visual 5
0d0fc3985f8 noise - (prefilter) diserial: change the rx start delay to more realistic 0.5 cycles
e8b144d7a9d noise - (prefilter) rendfont: set minimum width of scaled bitmap for font chars used in .l
eb23db35d9e noise - (prefilter) New systems marked not working ------------------------------ XDS-19P 
f966e52e6e4 noise - (prefilter) rendlay: fix off-by-1 error with alpha blended disk element
0524b105c18 noise - (prefilter) emu/debug/debugcmd.cpp: Added support for lowercase hex to printf/loge
b79289eff78 noise - (prefilter) New systems marked not working ------------------------------ Jin Xiu 
f93a04010a0 noise - (prefilter) emu/debug/debugcmd.cpp: Add NUL-terminated string argument support to 
b7b56f24f41 noise - (prefilter) imagedev/cassette.cpp, formats/flacfile.cpp: Added support for saving 
bd3084ca2ef noise - (prefilter) util/unzip.cpp: Work around spurious maybe uninitialised warning with 
6583232209d noise - (prefilter) diexec: remove unneeded memset on attotime object in constructor
04a25828521 noise - (prefilter) debug/express.cpp: Fix bad iterator comparison in postfix conversion. 
fb1a8b66de1 noise - (prefilter) New systems marked not working ------------------------------ Executiv
dc77e03d7f5 noise - (prefilter) New systems marked not working ------------------------------ Hammer C
067afa1a2e6 noise - (prefilter) util/cdrom.cpp: Zero entire output TOC structure in cdrom_file::parse_
7662be246fa noise - (prefilter) Fixed a few class memory access warnings.
733c17d48fb noise - (prefilter) New systems marked not working ------------------------------ Que Huan
d8dc50a8e77 noise - (prefilter) fastfred: correct XTAL
10a74f18b99 noise - (prefilter) emu/http.cpp, util/server_http_impl.hpp: Added override qualifiers for
57473cabc12 noise - (prefilter) New working clones ------------------ Double Dragon (Japan set 2) [l_o
df62ba1451b noise - (prefilter) util/cdrom, machine/t10mmc: Add preliminary support for multisession C
43a95685e1a noise - (prefilter) New systems marked not working ------------------------------ Nokia Mi
c83e1c5aa14 noise - (prefilter) Cleanup:
b2d602267fd noise - (prefilter) Various cleanups:
6e243e2f5c3 noise - (prefilter) debug: fix MT#08870, debugger tracesym regression
f569bf66e90 noise - (prefilter) util/ioprocs.cpp: Count zero actual bytes written on a write call as a
af79954d15b noise - (prefilter) drivenum.cpp: fix undefined behavior in find_approximate_matches (#124
ef22c02ba10 noise - (prefilter) sega/segac2.cpp: Addition of Print Club V3; some minor changes for the
10d9e0cd082 noise - (prefilter) devcpu: fix possible time travel issue in defer_access, z80: remove in
80d04627a63 noise - (prefilter) -util/corefile.cpp: Fixed core_file failing to propagate write errors.
0e459c17f59 noise - (prefilter) -machine/atastorage.cpp: Log disk geometry at verbose level (rather th
27ab2997b37 noise - (prefilter) New systems marked not working ------------------------------ Dice Mas
6e145763df2 noise - (prefilter) atlus/cave.cpp: used actual resonator valure for the Oki on donpachi a
48271af6806 noise - (prefilter) rendersw: Generate cosine table at compile time (#12513)
ab2451cb8d2 noise - (prefilter) -machine/genpc.h: Connect iochrdy properly. Also don't forward the sam
5c14cc707bc noise - (prefilter) emu/rendersw.hxx: Appease complilers that don't believe in constexpr t
9ae9e6c069b noise - (prefilter) emu/rendersw.hxx: Don't use class template deduction with large initia
c8c964065cc noise - (prefilter) Updated "CPU Tester" sample code so it will mostly build and work agai
1aa8abc3e5d noise - (prefilter) ioport: offset analog value by half a step because of rounding issue w
1725703539a noise - (prefilter) emu/debug/dvdisasm.cpp: Fixed bad display if view is scrolled horizont
546bf269bc5 noise - (prefilter) xtal: add 32.2159_MHz_XTAL
8edd5dbf59b noise - (prefilter) segas32: multi 32 master clock is 32MHz [Guru], also got rid of clock 
8f8c63013c1 noise - (prefilter) xtal: c++ style comments, remove list of xtals that could be purchased
082795deac0 noise - (prefilter) xtal: small correction to indentation (IIRC srcclean in the past did t
580e0a9638c noise - (prefilter) z80: use LOGMASKED instead of a macro for each log type, xtal: add 3.5
edbfe76b376 noise - (prefilter) smc777: Correct master XTAL frequency; add undumped 8041A to configura
09c80cf7943 noise - (prefilter) -igs/igs_m027.cpp: Hooked up I/O for Fruit Paradise and added layout f
812f17ad6ca noise - (prefilter) igs/igs_m027xa.cpp: Hooked up proper inputs, lamps and layout for Trip
698e1d89856 noise - (prefilter) srcclean in preparation for 0.270 release branch.
0125087cbe3 noise - (prefilter) -emu/render.cpp: Always translate coordinates if container is found (f
83811974793 noise - (prefilter) emu/debug, osd/modules/debugger/qt: Clean up #includes a bit
43584224ebb noise - (prefilter) util/chd.cpp, util/chdcodec.cpp: Made some APIs return errors rather t
beb81e48424 noise - (prefilter) chd.cpp: More API changes - Have metadata_find return std::error_condi
46521af5592 noise - (prefilter) util/chd.cpp: Made a few more member functions return error conditions
ad459a9025b noise - (prefilter) util/chd.cpp, util/chdcodec.cpp: Added a safer way to let codecs do sp
6423aae854b noise - (prefilter) Added a new modular JVS framework
b5c0c73f466 noise - (prefilter) emu/input.cpp: Guard against automatic integer promotion on arithmetic
8c8ed8bfc24 noise - (prefilter) emu/schedule.cpp: Mark one path as EXPECTED
54863e336c8 noise - (prefilter) New working clones ------------------ Ukiyo Box (Japan, v1.3.7) [Hammy
e9dcdb5200d noise - (prefilter) machine/t10mmc.cpp: Added stub CD-TEXT TOC read; util/cdrom.cpp: Handl
2c8de2ee297 noise - (prefilter) -util/cdrom.cpp: Fixed issues with CUE, TOC and GDI parsers. (#12948)
f8705815bda noise - (prefilter) util/cdrom.cpp: Change fprintf(stderr, ...) calls to osd_printf_error
21e1b48a014 noise - (prefilter) New working clones ------------------ Mad Motor (prototype, set 2) [Sn
ea02851fc85 noise - (prefilter) diexec: don't eat negative cycles with abort_timeslice when icount<0
fb8198689ac noise - (prefilter) devcpu: do an abort_timeslice instead of eating all cycles on defer_ac
f292ae5b747 noise - (prefilter) Revert "devcpu: do an abort_timeslice instead of eating all cycles on 
fa14f782ae8 noise - (prefilter) rendersw: fix apparent bug in draw_quad_palette16_add
1c50756b3a4 noise - (prefilter) emu/rendersw.hxx: Support RGB multiply blending with 16bpp textures.
bb305af46e7 noise - (prefilter) emu/rendersw.hxx: Get rid of obsolete overly specific blend function.
381080970e2 noise - (prefilter) rendersw.hxx: Fix bad use of u32 reference type in 1c50756b3a43811fcd5
7d7b1fadb9e noise - (prefilter) New systems marked not working ------------------------------ CPS1 Mul
f4f5fb5ebf7 noise - (prefilter) screen: prevent race condition on drivers with vblank at y=0, causing 
8cd93744894 noise - (prefilter) rendlay: fix crash with rect element alpha of 0 < n < 1.0/255, misc: s
12401f1429b noise - (prefilter) emu/natkeyboard.cpp: Add CAPSLOCK, CR and LF escapes to post_coded
872afd9ee53 noise - (prefilter) misc/vamphalf.cpp: Add screen raw parameters
ba493adcfa5 noise - (prefilter) mconfig: allow sub-mcfg to unset perfect quantum
e462f6a5399 noise - (prefilter) bus/rs232/teletex800: Add front panel layout. [Curt Coder]
99b228771c1 noise - (prefilter) tilemap: account for flipped tilemap in get_info_debug, diablo: update
43c5edd1391 noise - (prefilter) atari/tank8.cpp: Add addressable latch devices and XTAL definition; us
32d45e173bf noise - (prefilter) util/corestr.cpp, sound/sdl_sound.cpp: Added missing standard library 
da5ba370318 noise - (prefilter) device: round scaled clock to nearest integer
efee42e5e49 noise - (prefilter) casio/ct8000.cpp: Emulated Casiotone 8000 keyboard and related systems
733f24e153d noise - (prefilter) pci/zr36057.cpp: add SAA7110A stub
762b250b7e4 noise - (prefilter) cdrom: fixed wrong track number in error messages [Robbbert]
57f6141e419 noise - (prefilter) ddragon3_v: small cleanup to source code spacing
c2155411874 noise - (prefilter) screen: fix possible race condition at reset_origin if vblank start ==
65c263749e1 noise - (prefilter) util/chd.cpp: Hacked around GitHub #13029 (issues creating delta CHDs)
0a861ff810f noise - (prefilter) Cleaned up some stuff:
a026c8df127 noise - (prefilter) New clones marked not working ----------------------------- Jin Hu Lu 
be13ded5f6b noise - (prefilter) Fixed some things causing save states to be unportable:
914fc4477b4 noise - (prefilter) vax: Minor disassembly refinements
b860e736f6b noise - (prefilter) Miscelaneous minor fixes:
8ca4fcbbf98 noise - (prefilter) ioport: fix possible issue where 4way joystick value could be invalid
1dca832b373 noise - (prefilter) -cpu/e132xs.cpp: Improved exception emulation:
08875eebfa9 noise - (prefilter) emu/diexec.cpp: Deal with the annoyances of the timer state machine
1779ca5db6f noise - (prefilter) screen: remove obsolete loadstate workaround
1f871c19ee6 noise - (prefilter) -A few recompiler adjustments:
cd3e00161a3 noise - (prefilter) Clones promoted to working -------------------------- Chess-Master (mo
ec7eb50bf6d noise - (prefilter) casio/cps200.cpp: Added a skeleton Casio CPS-2000 driver; also improve
8aec17bcc6e noise - (prefilter) debugcmd: correct trace file append
b1d2a52ddd9 noise - (prefilter) debugcmd: update prev commit: change out+app to in+out+ate
e3f386c2a90 noise - (prefilter) Made PTR64 a makefile-only thing - it isn't necessary in the code.
25dd2486462 noise - (prefilter) natkeyboard: limit buffer size to 4*8MB
d75e59c5a41 noise - (prefilter) natkeyboard: fix regression from prev commit
b777e6af9c1 noise - (prefilter) Fix for dkong and avi recording
876871e4457 noise - (prefilter) sound: disable verbosity by default
e41fb3b287f noise - (prefilter) Some fixes
8be5131548b noise - (prefilter) More fixes
05d52f91b82 noise - (prefilter) Make avi able to do more than stereo
3d076473204 noise - (prefilter) namcos12_cdxa: fix crash on set output gain
e0268b35b2a noise - (prefilter) sound: make sure m_samples_to_update is 0 when returning from update()
99fc7b2c7f4 noise - (prefilter) device_mixer_interface: set samplerate to osd rate, like how it was be
649d5af11a6 noise - (prefilter) Revert "device_mixer_interface: set samplerate to osd rate, like how i
838f21fb865 noise - (prefilter) sound: add sync time to savestates
41429e8ce96 noise - (prefilter) igs/igs011.cpp: Improved inputs and DIP switches for xymg and wlcc.
6e965f9ce91 noise - (prefilter) Add resampler configuration saving and documentation
8b8cecbf289 noise - (prefilter) Fix typo in lofi resampler
65f6f575f26 noise - (prefilter) Fix wavwrite
8b46dc83274 noise - (prefilter) Fix resampler config interaction with reset
2e9d4671d86 noise - (prefilter) DUH
b09c1e94321 noise - (prefilter) Who knows, maybe I'll get it right on the third time
0a66df7904f noise - (prefilter) sound: only rebuild resamplers when necessary
463eea3ec82 noise - (prefilter) resampler: Correct history sizes to take desynchronization into accoun
b1bc1d310af noise - (prefilter) Correct sample counts on update
2693d902716 noise - (prefilter) sound: avoid updating at t=0, the environment may not be not initializ
ff45110643c noise - (prefilter) sound: update prev commit with different init detection
64e57e19ff0 noise - (prefilter) sound: update prev commit with different init detection (retry)
fe8769d0ebb noise - (prefilter) lofi resampler: Better step precision to avoid crackling
c5aa2a22f77 noise - (prefilter) effects: Recompute filters after loading the configuration
f17cf5475a8 noise - (prefilter) [win] debugger crash: Add fallback to "0" if address evaluation fails 
fa327098594 noise - (prefilter) emu/inpttype.ipp: Group default double-up game control assignments on 
7ba2d22d474 noise - (prefilter) Remove obsolete options (compressor will be in effects, speaker report
9182ed56b52 noise - (prefilter) Rework a case where the sound defaults are not put in place in correct
7e295d75c08 noise - (prefilter) compressor: remove printf spam
29a7d13c45e noise - (prefilter) sound: fix incorrect detection of config loading when the driver file 
167754f0ada noise - (prefilter) EQ: detect when not actually used
8c9f6278b23 noise - (prefilter) audio compressor: make it a little less enthusiastic
9d64f84eca5 noise - (prefilter) sound: Fix synchronous streams
7e3c5f1b7af noise - (prefilter) sound: enhance portaudio support.
726b7f197b6 noise - (prefilter) sound: Fix save states
28709b97cdd noise - (prefilter) sound: Do not interpolate when not changing rate, fixes pbobble2 and g
dd3bff260af noise - (prefilter) sound: re-add support for -volume option (works same as before sound r
48b4632d216 noise - (prefilter) options: fix range checker with negative values
8b7f480073b noise - (prefilter) sound: no need to save master volume of 0
af6f9ff3842 noise - (prefilter) fntspcian: change company string to hack
516e3f31710 noise - (prefilter) emuopts: correct typo
5f4478e1b0c noise - (prefilter) sound: disable error.log "Sound reset" message by default
1a97bc2159d noise - (prefilter) sound: update prev commit (sound reset msg is not OSD)
e0eba0e729a noise - (prefilter) sound: update mapping when changing audio mixer configuration (fixes i
b39e6846221 noise - (prefilter) debugger: symlist usability + symbol table extensibility (#13694)
1e8c8d01b7e noise - (prefilter) remove obsolete wave (cassette sound) device
d37a9fd48c9 noise - (prefilter) sound: Correct handling of streams closed on the osd side.
920f1602f2d noise - (prefilter) sound: tell the osd about the update
912c0af812c noise - (prefilter) portaudio: do not mess up on shift-f3
e7e9e8e1b5f noise - (prefilter) emu/validity.cpp: Validate device input defaults. (#13758)
d0de49a04d7 noise - (prefilter) emu/validity.cpp: Fix typo in error message
4e599009d89 noise - (prefilter) device_mixer_interface: set rate to SAMPLE_RATE_OUTPUT_ADAPTIVE (highe
6a5ce022d34 noise - (prefilter) sound: fix default.cfg load not applying default effects, and rename d
a9ef77d049d noise - (prefilter) sound: simplify prev commit
7653173918e noise - (prefilter) screen: add optional screen update callback for svg screens
7fa33906ae8 noise - (prefilter) sound: fix sync issue when starting a stream that was stopped
6930849d968 noise - (prefilter) sound: Fix extremely subtle and rare problem that could happen when ch
542f7da17a2 noise - (prefilter) emumem: correct shifting direction on masks when importing a map with 
4c6af4121b4 noise - (prefilter) debugcmd: no need to try to convert string_view to const char*, fix po
9f227c1f1ae noise - (prefilter) -igs/igs_m036.cpp: Nicer short names for a couple of games.
426b0c62769 noise - (prefilter) sound: fix crash after loadstate with different resampler setting
4fe5340cd32 noise - (prefilter) reverb: srcclean and blind attempt at Windows fix [R. Belmont]
d232fabd5a5 noise - (prefilter) reverb.cpp: Trying again on Windows. [R. Belmont]
e67b16e9766 noise - (prefilter) resampler hq: Remove the hard cutoff ceiling at 20K. It was an initial
ae23e1eff90 noise - (prefilter) reverb: detect preset when entering menu
1e71f7a0d3b noise - (prefilter) filter: don't try to filter above nyquist freq (or slightly below it)
11edc7d5169 noise - (prefilter) reverb: update to prev commit, don't hardcode "Default" in preset stri
49ed0d14722 noise - (prefilter) ui: improve control over audio filter cutoff freq
39d1f66ec64 noise - (prefilter) reverb: fix config_load typo
737b0779ba4 noise - (prefilter) reverb: add more to default_changed
a7c08350645 noise - (prefilter) equalizer: change freq to u32, apply same nyquist freq fix as 1e71f7a0
9f32bcf584a noise - (prefilter) effects: Fix reverb decays, disable by default reverb and compressor
768b45285be noise - (prefilter) audio_effects/reverb.cpp: Add more missing initialization
ca75ff36a2c noise - (prefilter) dpatrol: added bd3.d1 prom [Bitsavers] (removed one of the sets since 
9033932679e noise - (prefilter) compressor: add infinite release option (eg. combine with input gain o
f89f3b174c9 noise - (prefilter) Revert "compressor: add infinite release option (eg. combine with inpu
667be3c8f1a noise - (prefilter) compressor: change channel link range to 0-1
b9b0e336d25 noise - (prefilter) audio_effect: add reset_all for resetting all variable settings
9d161515585 noise - (prefilter) filter,equalizer: change default q to sqrt(2)/2
0b697224d2b noise - (prefilter) multi32: Separate the speakers that were in different cabinets sound: 
5a756a91f9e noise - (prefilter) equalizer: change default bands to 100,330,1k,3,3k,10k
fb80b473183 noise - (prefilter) equalizer: check band mask instead of db when building filter
90705796220 noise - (prefilter) diserial: reset the receive register when changing frame format or the
93516cd66e6 noise - (prefilter) osd/asio.h: Move some duplicated code into the common header.
103ea6a5949 noise - (prefilter) sound: correct dreadful typo that killed stereo
b161915d845 noise - (prefilter) audiomix: add full/channel route via menu instead of f/c keys
f1b88c41c62 noise - (prefilter) filter: move notch filter check to ui
c9f1ac8583b noise - (prefilter) resampler: clamp final output to -32768, 32767
e6c38120380 noise - (prefilter) sound: fix problem when default devices are missing
a2006d3c5da noise - (prefilter) remove leftover debugging
bb1d23c13a6 noise - (prefilter) inpttype: add secondary default key (backspace) for UI Back
3cb13d9ac2d noise - (prefilter) Revert "inpttype: add secondary default key (backspace) for UI Back"
54c3112c0f4 noise - (prefilter) sound: fix initial -volume setting
db8f463b491 noise - (prefilter) ui: finer control over hq resampler settings
63528f8379d noise - (prefilter) resampler: safety check for filter len
b53cd1efd61 noise - (prefilter) compressor: correction to input gain calc
71694485cd8 noise - (prefilter) compressor: increase max input db so input gain won't distort the sign
ad81c4e55f2 noise - (prefilter) compressor: re-add infinite release option, and also infinite ratio
ed324d42999 noise - (prefilter) tilemap: small optimization to scroll cache, m72: do spritelist fill w
190fd35eb57 noise - (prefilter) gemini: lower ym volume, small correction to mcfg
90d03538692 noise - (prefilter) sound: misc fixes
379eb6908a7 noise - (prefilter) emu/debug/debugcmd.cpp: Have print command insert spaces between numbe
2cfe0cb0093 noise - (prefilter) Fix symlist default CPU (#13886)
9b26298b384 noise - (prefilter) -cpu/drcbex86.cpp: Not nuking the destination register on 64-bit rotat
52d7efa452d noise - (prefilter) palette: do assert() check before accessing array
638a745e85d noise - (prefilter) heathzenith/h8.cpp: Implement H8 Bus (#13560)
1ae8aca9edf noise - (prefilter) Add support for an ADI keyboard for an unknown system [Dirk Best, Bike
095418aec53 noise - (prefilter) emu/debug: Extended memory commands for region and space (#13767)
c346566cd8d noise - (prefilter) diserial.cpp: Avoid updating data frame if nothing changed (#14105)
fae71cc8261 noise - (prefilter) diserial: don't use bitwise OR on bool, small cleanup to spacing
64186873c0f noise - (prefilter) Clean up some stuff:
27ca121f956 noise - (prefilter) emumem: Optimize a specific but useful case. emumem_mview: Add forgott
5609ab501f1 noise - (prefilter) emumem.cpp: Restrict optimization of 27ca121f9566b9ecb1699e0af33c8688a
2c121c41e96 noise - (prefilter) emumem.cpp: Optimize the optimization further
840d976ff39 noise - (prefilter) Added the Sord Future 32 alpha. It needs interrupts, and they're compl
d7bac115eaa noise - (prefilter) Fix typos in 840d976ff39211f5c682ebb063762ebec77796e9
fdce0968367 noise - (prefilter) render: do a 2-pass for updating artwork clickable zone input field st
44910ff51e4 noise - (prefilter) render: no need to do std::transform here
dd75a578741 noise - (prefilter) render: yoda style for loop like the surrounding source
47286a56f9f noise - (prefilter) rendlay: change legacy marquee ui toggle to Marquees instead of a 2nd 
b81ca1f3aad noise - (prefilter) rendlay: remove invert flag from 7seg element, add inverted 7seg outpu
64a24c60655 noise - (prefilter) emu/emumem.cpp: Work around regression in gaelco3d.cpp games by disabl
392053bee98 noise - (prefilter) -dynax/ddenlovr: Credit limit should be multiplied by coin rate for Ha
8ceb26829f7 noise - (prefilter) emu/emumem_mud.cpp: Prevent subunit offsets from being masked out in h
9591eca3324 noise - (prefilter) emumem_mud: Short-term fix to some crashes, need more thinking though
453c1be7885 noise - (prefilter) video/ym7101.cpp: fix name tables with uppermost bit discarded in 64 K
defe7503522 noise - (prefilter) laserbas: correct clocks (music pitch and speed)
2a9b6a1097f noise - (prefilter) Fix parsing of unary ! operator in debug expressions
5ecdbde318b noise - (prefilter) Prevent automatic attempts at loading or creating loose image files wi
12bfdf939ee noise - (prefilter) Only allow command line image creation when file is not found; save st
aa5b19dd075 noise - (prefilter) emumem.cpp: Fix typo in comment
d0f81f88b7c noise - (prefilter) fill q.value was not working, you will not guess what the bug was
2674fa08c79 noise - (prefilter) Added skeleton for Convergent AWS-220, hooked up basic display, boots 
8a69e889431 noise - (prefilter) new cpu core (start of disassembler): dsp563xx
6675c28390e noise - (prefilter) emu/video/rgbutil.cpp: Fixed signature of methods for Altivec/VMX.
f67d8691d68 noise - (prefilter) util/zippath.cpp: Handle "." directory and going up to or up from it. 
3e3209aa1ff noise - (prefilter) New systems marked not working ------------------------------ Koi Koi 
81aaeb52eba noise - (prefilter) bus/a2bus/a2ultraterm.cpp: Various fixes - Correct CRTC type - Correct
dc20607ff4c noise - (prefilter) emu/video/rgbutil.cpp: Hopefully fix PowerPC build.
465980cd065 noise - (prefilter) Fix text clipping introduced by https://github.com/mamedev/mame/pull/1
c3258dea358 noise - (prefilter) rendlay: guard against possible divide by 0
55c70b54e22 noise - (prefilter) -igs/igs017.cpp: Support both control panels for Tarzan train games.
1109bdf2f17 noise - (prefilter) sound: also sync the speaker streams, fixes the crashing after ~24hour
470097f4907 noise - (prefilter) sound: fatalerror when trying to change the sample rate while in strea
7429d383fe8 noise - (prefilter) sound: typo fix
11f79c3d538 noise - (prefilter) emu/save.cpp, util/png.cpp, various disk and cassette formats: Use mul
ea26e641388 noise - (prefilter) sound: Add error for problematic initial sample rates
0e5e99b7a2c noise - (prefilter) xtal.cpp: Add value for later use
8364a943ea0 noise - (prefilter) -scripts: Cleaned up devices build scripts a bit:
e25ef95c462 noise - (prefilter) frontend/mame/luaengine.cpp: Better handling of options:
6907b0eb4df noise - (prefilter) -util/options.cpp: Shuffled numeric option conversions:
ca6756d4635 noise - (prefilter) noscreens.lay: add red background
c1ada7cc13b noise - (prefilter) noscreens.lay: add footnote with more verbose msg
6b8688850b3 noise - (prefilter) LUA: Ensuring that `entry:default_value()` returns the correct type (#
8ce049d9dfc noise - (prefilter) bus/nscsi/tape.cpp, util/ioprocs.cpp: Fixed last remaining tautologica
a16e0f07e74 noise - (prefilter) emu/debug: Use "classic" locale for debug console.
962bfd5b1df noise - (prefilter) emu/romentry.cpp: Found another thing that needs to use the "classic" 
6cb0ec64ac8 noise - (prefilter) Miniforce and CPU1 (#14873)
7259512dfda noise - (prefilter) luna/dma: implement what I think is what really happens
09ebceb526e noise - (prefilter) Miscellaneous minor changes:
307f9d8d5ae noise - (prefilter) Merge commit '24658d27e85' into HEAD
f26bf53a343 noise - (prefilter) Revert "Miniforce and CPU1 (#14873)"
4b850b46abf noise - (prefilter) sound: alternate method for checking if machine is not yet running
6e0405e4d95 noise - (prefilter) emu/debug: Allowed device_state_interface to participate in global sym
6a1860e4203 noise - (prefilter) inpttype: add p4 analog direction control defaults
9c1eb3d1337 noise - (prefilter) cpu/sharc: Improved memory access code:
a00dffbfee9 noise - (prefilter) emumem_mview: on switch, do nothing if selected slot is same as before
339f390619a noise - (prefilter) emumem_mview: remove extra negative check after prev commit
09f33738eaf noise - (prefilter) Miscellaneous fixes:
f5607a93510 noise - (prefilter) misc/statriv2.cpp: got rid of tag lookups, made use of derived classes
76a0dde560b noise - (prefilter) emu/diimage.cpp: Notify on changing preset images.
03fa21d73ea noise - (prefilter) ui: include fastforward in unthrottle_mute, sound: don't send sound to
967f3636c81 noise - (prefilter) sound: change abuffer resync to more abrupt
c468a345e30 noise - (prefilter) sound abuffer: after overflow, reduce buffers to 1 instead of clear
a8934416a3a noise - (prefilter) sound: forward audio latency setting to abuffer
eed78486114 noise - (prefilter) z80,6502,i86: no need for that m_reset_time local variable
3056647e01e noise - (prefilter) misc: normalize blue palette
6468f2eae51 noise - (prefilter) -dynax/ddenlovr.cpp: Use slotted control panels.
a4ba1e57ca1 noise - (prefilter) Fixed various things that C++20 doesn't allow:
c13ed1630bd noise - (prefilter) jaminator, beena, tvochken: Fix slot option name clash
21defbea953 noise - (prefilter) Fix up more stuff for upgraded tools, etc.
22915ef8fb1 noise - (prefilter) sound: fix a convergence problem when a rate-adaptive stream is not co
3b1bc6244cc noise - (prefilter) screen: correction to update_partial(scanline) logic after prev commit
0fa3532209e noise - (prefilter) screen: fix possible issue with update_partial
66599ed87a6 noise - (prefilter) emu/disound.cpp: Improved calculation of sound_requested_outputs_mask.
47377bfe7a4 noise - (prefilter) emu/debug/dvmemory.cpp: Recomputing memory view based on evaluated sta
421d94b3484 noise - (prefilter) namcos21: tweak video timing and some other clocks
47d954469ae noise - (prefilter) dvmemory: redo 47377bfe7a49cf301957cc90f6ac5f08a59c503c
936800b17c1 noise - (prefilter) cinematronics/leland.cpp: Better default trackball sensitivity.
c55b7121935 noise - (prefilter) frontend/mame/clifront.cpp: Honour -noreadconfig for command line verb
e61c7f7c8b8 noise - (prefilter) frontend/mameopts.cpp: Fall back to settings from INI files later in t
f695e757c57 noise - (prefilter) ioport: set disable_side_effects on internal frame update (eg. if read
571f3d4b723 noise - (prefilter) Revert "ioport: set disable_side_effects on internal frame update (eg.
8031d62240d noise - (prefilter) util/zippath.cpp: Adjusted error handling.
d5c87dddee1 noise - (prefilter) image.cpp: Fix regression with opening sockets
448f067501b noise - (prefilter) -Partially revert 12bfdf939eecce62a875b800b94872bd938fab0e due to MT09
c512a51abf6 noise - (prefilter) Merge branch 'release0288' into HEAD
3b80cb30d48 noise - (prefilter) src/emu: #include <cstdio> for future-proofing
e509909bd59 noise - (prefilter) emu/rendlay.cpp: Removed reel component.
1ed09f8975d noise - (prefilter) Clean up some stuff after running valgrind:
a88d9695e0b noise - (prefilter) -emu/romload.cpp: Hopefully avoid potential crash loading delta CHDs.
01c268f5318 noise - (prefilter) -emu/diimage.cpp: Fixed unloading media when the core doesn't open the
9e781163995 noise - (prefilter) Zilog System 8000 (3 new NOT WORKING) + Z8010 MMU + Z8000 CPU improvem
7e7179fc448 noise - (prefilter) New working systems ------------------- EACA Genie III (Germany) [Dirk
160d9c29522 noise - (prefilter) emu: Add -rtc command-line option for fixed baseline time overrides (#
d0ecfca7b5a noise - (prefilter) machine/s97801.cpp: Emulated the Siemens 97801 terminal. (#15697) [Dav
b67c1a27eed noise - (prefilter) layout/s97801.lay: Reference screen by tag, don't bother with screen-o
1cf0f9e9865 noise - (prefilter) chdman: add parameter for add/remove pregap in createcd, extractcd (#1
a4f77431604 noise - (prefilter) src/lib: Replace eminline bit manipulation functions with C++20's <bit
c23567b5095 noise - (prefilter) 3rdparty/lzma: Updated to upstream version 26.02.
264ebe5a6a5 noise - (prefilter) cbasebal: improve clocks
c1bede02230 noise - (prefilter) emu/emumem_mview.cpp: Note bug
ac47a71ce13 noise - (prefilter) chdman: add GDI pregap support (#15870)
954cbbe49ff noise - (prefilter) util/chd: use modern C++ standard library facilities (#15889)
e5e82312c2c noise - (prefilter) util/chd: fix several size and range handling issues (#15893)
b93961fd52f noise - (prefilter) chdman: retain session data (#15886)
e0b94b77a59 noise - (prefilter) chd: Handle short writes (#15902)
7026ff1e723 noise - (prefilter) gen_fifo: FIFO is uppercase, emupal: capitalize device name
2d0a09baefc noise - (prefilter) ram_device: Convert to slot device to fix limitation of only being abl
ebe430d9fd5 noise - (prefilter) Revert "chd: Handle short writes (#15902)" (#15936)
6cdf1cf7004 noise - (prefilter) util/chd.cpp: Stage the correct set of changes.
20661546b2d noise - (prefilter) chdman: Fix session parsing by extending the read_metadata function to
1b09ee11d08 noise - (prefilter) cbmiec/cmdhd: Added front panel layout. [Curt Coder]
35c962eba58 noise - (prefilter) screen_svg: re-add aspect ratio info (useful for determining driver sc
76904265cd2 noise - (prefilter) cbmiec/fd2000: Implement CMD FD-2000 and FD-4000 disk drives. [Curt Co
09b09f7b27f noise - (prefilter) checkmanj: lower ay volume
107ab481840 noise - (prefilter) cbmiec/serialbox: Implement Serial Box IEC printer buffer. [Curt Coder
8aa5aebef02 noise - (prefilter) New systems marked not working (#15946)
09b7b3a7a54 noise - (prefilter) util/ioprocsstream.cpp: Added <iterator> needed for GNU libstdc++.
c77f0762459 noise - (prefilter) util/xmlfile.h: Added <cstdint> and <memory> that are somehow implicit
cd91ce395ff noise - (prefilter) Explicitly include strformat.h for future-proofing
8d155c368b0 noise - (prefilter) util/archiver.cpp: Avoid use of zutil.h (GitHub #16065).
f5d36b3bc25 noise - (prefilter) emu/ioport: add missing Tab key mapping
607f9dc340b noise - (prefilter) sega/segasp.cpp: Dumped PIC16C621A microcontroller for 100&Medal KAZAA
0b4076983d8 noise - (prefilter) Tidied some stuff, mostly related to recently-changed things.
764de9b5b48 noise - (prefilter) emu/divtlb: retire a fixed entry loaded with no pages (#16146)
0ee5c47faa7 noise - (prefilter) cpu/powerpc: Fixed more long-standing 603 TLB-related bugs. [R. Belmon
6fa8320c8d6 noise - (prefilter) misc/3do_madam.cpp: fix transparency for non-rectangle packedCELs
e638727a7a0 noise - (prefilter) emu/screen.cpp: Fix vpos()/hpos() for the case where a device is still
1736a9595b8 noise - (prefilter) util/avhuff: enforce audio channel limit consistently (#16077)
f653fca8152 noise - (prefilter) Systems promoted to working --------------------------- Qume QVT-70
457a60cf8fd noise - (prefilter) xtal.cpp: Add another value for later use
c9e87a6b7e0 noise - (prefilter) util/cdrom.cpp: Support CD+G Discs (#15910)
c4fc5eb7905 noise - (prefilter) Sound: Fix microphone input stride for interleaved capture (#16309)

### Triaged

d1172bf710f noise - romload/chd: delta CHDs find parents in parent sets; no driver API
052b5500264 noise - romload internals: software media search path
0e8fdbecdd1 noise - romload tidy (set_disk_handle string_view)
ba621ec24df noise - fixed PORT_CROSSHAIR_MAPPER macros; later reworked by 5f4e3730d9d
6e60af32c1e docs inbox layout_script.rst: emu.bitmap_* in sandbox, element set_draw_callback
ab892a4bc7c noise - layout_files.rst example links bumped to 0.261
0f237da678a noise - artwork cleanup (.lay files)
05e69b43e97 noise - Zstandard for zip/CHD
c401273bdab migration timers emu_timer/synchronize param int -> s32; topic already says s32
ebcb8b159d0 noise - emufwd forward decl
b8077084703 noise - image media-change notifier for UI/Lua
59cbd883f81 docs inbox layout_script.rst: device/image/slot enumerators in sandbox
a09fd45203c noise - dipty whitespace
66103142647 migration inbox UTF8_* macros in input defs -> u8"" literals (mame-review I-3)
688fecf5740 migration inbox remaining UTF8_NBSP/MULTIPLY/DEGREES removed (prestige.cpp, UI)
828a54af4e3 noise - slot set_fixed/set_default_option return *this (chainable); no idiom change
73cfbde8abc noise - image_feof removed (unused)
b5cae0e6f80 noise - "authors:" line added to layout comments
e4f44632c7a deprecates inbox pcat_base_state constructor [[deprecated]] (leaky southbridge)
69c3cd7daba noise - bitstream fix
229d19de63e noise - revert of above
0b15781e698 noise - re-apply bitstream fix
d98993d7ff9 deprecates inbox device_network_interface: get_mac/get_promisc gone, save states work
334ec12e004 deprecates save-states late save_item now always fatal (was only for SUPPORTS_SAVE); topic already says it throws
1615b8551a3 new inbox util::read/write/read_at wrappers; allocating fread overloads removed from image interface
657c28b9857 noise - bitstream fix
3e4ed5d6fe4 noise - core_crc32 removed; no driver users
f28fe7db31d noise - OSD MIDI/net cleanup
6bccd589c1a new memory-spaces device_rom_interface::set_space(tag, spacenum) to read through an existing space
d73c21c097a noise - fix-up of 6bccd589c1a
4ddd26fe21e docs inbox layout_files: clickthrough attr; layout_script: view pointer callbacks
8e7af961c65 docs inbox layout_files: view showpointers attribute
4980f881393 deprecates inbox MACHINE_CLICKABLE_ARTWORK removed (pointer display now from layout)
e22aae63a19 docs inbox layout sandbox gains Lua math
0133d14353c noise - doc typo
793de967753 docs memory-spaces memory.rst: contention handlers, taps; new cpu_device.rst (interruptibility)
8c5a984fa0f noise - proofreading of 793de967753
f3532784f8a docs inbox contributing: software list + wiki notes for media-booting systems (= mame-review S-4)
3c9f7829d98 noise - rst markup fix
ee9c41d71e7 noise - emu_fatalerror VC++ fix
667c4e4f6d4 new inbox palette format GRBx_444
9f6c0de566d noise - misc cleanup
e71dcb76dfb new inbox palette format xBGR_333_nibble
1949b85c815 new address-maps memory_view::exists()
15dd5beab46 noise - natkeyboard post() string_view
dc26fcd1bb2 deprecates inbox [DECLARE_]CUSTOM_INPUT_MEMBER removed -> ioport_value fn()
351dfca54b1 noise - masked read_byte/write_byte accessors (CPU-core plumbing)
b8889905639 deprecates inbox execute_input_lines() removed from device_execute_interface
608499617a3 deprecates inbox execute_burn() override removed
afab68e6c2c noise - diserial stop-bit fix
48933ef893c migration inbox ATTR_COLD added to lifecycle overrides in ~2975 files (mame-review D-2)
aeaf19f2640 noise - diserial parity table removed (internal)
ded2280e3fc new inbox PORT_GM_NOTE / PORT_GM_C4... piano key names
53276e44d46 noise - srcclean
fc41ef0c9a7 deprecates inbox PORT_DIPLOCATION validation: empty switch name / switch number <1 now errors
471b1261c1c new object-finders .portr/.portw/.portrw accept ioport finders
e989c7d00ff new inbox GFXDECODE_DEVICE_REVERSEBITS
5f4e3730d9d new inbox port field callbacks take FUNC()/NAME(): PORT_CUSTOM_MEMBER(FUNC(...)) etc.
d66d88b1ab0 deprecates inbox dirtc set_current_time no longer virtual; devices use rtc_clock_updated/rtc_battery_backed
152389867e9 new inbox bookkeeping coin_counter_reset_count / reset_dispensed_tickets
b7a20d44933 new memory-spaces cpu_device::retry_access() (WAIT lines) vs defer_access()
5e63771946a docs memory-spaces cpu_device.rst §3.4: access_before_time/delay, defer_access, retry_access
97ca2ae8d38 noise - doc typo
b1181f86023 new inbox debugger_wait_hook() for wait-type instructions in CPU cores
f7896632443 new inbox ROM_COPY source region relative to device (via sibling(); replaced next commit)
f16cd0249f1 new inbox ROM_COPY tags resolved relative to the current device in romload
076147c601a deprecates inbox PORT_VBLANK/PORT_HBLANK removed
43d61833e4a new inbox PORT_CHAR(0) is NUL; PORT_CHAR() skips a shift position
7a755b7d73f deprecates inbox MACHINE_IS_SKELETON[_MECHANICAL] removed
780490d9ac6 noise - srcclean
9c3566728e4 new save-states device_gfx_interface marks GFXDECODE_RAM entries dirty after load
44284c5eaa5 noise - bitswap<N> constexpr
f39baa51dc0 noise - mfpresolve (delegate internals)
5e09f88a2b3 noise - build fix
adee79cf846 noise - build fix
2ffd6a09aff noise - DRC back-end
b7a80b1704e noise - data_accessors removed (DRC dispatch)
cea7758f4f5 noise - DRC fix
56a55eb6ce7 noise - screen partial-update internals
dfcb1350c4e new inbox palette_device::read32_ext/write32_ext
5f6296049ba noise - misc
28ec18ab96b migration interrupts-devcb input_state() -> input_line_state(); current_input_state() removed
0826ae066a1 noise - input_line_state return type back to int (part of above)
98b18d69f7c noise - timer ordering on load, pulse overlap fix
3e3d27dde52 docs inbox uml_instructions.rst started (DRC front-ends)
de406415556 docs inbox more UML instruction docs
19b42381d64 noise - EXPECTED hint in cache lookup
a389a3393e9 new interrupts-devcb devcb binder .remove(); topic already states it (Since missing)
4faede19051 noise - view range computation fix
6d9f657e951 noise - natkeyboard buffer fix
9058810fe26 deprecates inbox set_promisc removed; network devices filter addresses themselves
670e2062cb0 noise - OSD network globals
d0f1c15a0f6 new sound-streams new sound infrastructure; topic is built on it (captured)
f68b2d87a12 docs sound-streams proofreading of sound docs (captured)
43b67a5ddc5 noise - sound.h warning fixes (friend removal, enum : u32)
f0e38cbe5be new save-states SAVE_UNSUPPORTED is captured; device flags::NOT_WORKING is not
653a2292b1c noise - LoFi resampler + UI; sound_manager internals
bd99a5d7f88 new sound-streams stream timing accessors documented (§3.4); sample_time()/sample_index() removed, end_index() redefined
c0fa1306b8c noise - compressor audio effect; user-menu docs only
80412524edc noise - effects thread decoupling, internal
116d8749f7d noise - one more palette format enum (xGRB_444); no idiom change
41d587d6073 noise - resampling/timing internals; osd muldiv64 helpers
1050ddce5bc new sound-streams unknown()/map_on_request_only() speaker positions (already captured)
335639e65f3 noise - WASAPI/osd; whitespace in disound.h/sound.h
1c553068418 noise - sound_manager::no_sound()
f25dcd04d29 noise - set_option_device_input_defaults_all, reverted by 67197ee631b
05d798c1b31 noise - spelling
4c71d2d089e noise - OSD node display names
67197ee631b noise - revert of f25dcd04d29
73b7cdabef5 noise - throttle/speed fixes
8009397404c noise - SOUND_DISABLE_THREADING build switch
f0e6df80480 deprecates sound-streams drops front_floor()/seat(), adds lfe(), osd::channel_position (already captured)
5092ad921bf noise - ROM loader warning counting
15b657c5cf9 noise - osd channel_position init order
72251989ad8 migration inbox enable_hilights()->enable_highlights(); palette saves shadow/highlight config itself
af10f3f21cc noise - UI/localisation; sound_manager signatures
6b335b5475a deprecates inbox TILE_LINE_DISABLED removed (use cliprect); tilemap now does row+column scroll together
f6178f3c2b1 noise - comment on VIDEO_UPDATE_AFTER_VBLANK (still "hack, remove me")
78f4e7c3ee6 new inbox tilemap blitter callback for custom scrolling (set_blitter_callback, TILE_BLITTER_MEMBER)
54aa3f1fea0 noise - resampler defaults
0fb8763322f new inbox DEF_STR 10C_1C, 1C_10C/20C/25C/50C/100C; 87 drivers migrated off literal strings
56c6e007981 noise - sound mapping internals
fe086b54cd0 new inbox DRAWMODE_SHADOW_PRI for priority-aware shadows in transtable drawing
e298ea57279 noise - gain setters moved out of line; float literals in k054321
3fe7535cb1f noise - missing \n in diserial logerror
f1fc4825414 docs - softlist: one value per info element; covered by mame-review SL-9, outside topic scope
02bdea66ea9 noise - emumem handler dedup (reverted/reapplied)
59a3894e554 noise - revert
f3d72937852 noise - reapply of 02bdea66ea9
faa0971062a noise - refcount fix
0480c0384e2 docs inbox layouts: views no longer processed last; elements/groups must precede use
a418fb42671 docs inbox UML reference: instruction-size prefixes, table reformat
049ded91077 noise - emumem_mud shift fix, reverted next commit
e6206590059 noise - revert of 049ded91077
366df9419cc docs inbox UML FP arithmetic documented
72f1d62b4b3 docs inbox UML more FP instructions documented
e49cbb909f3 docs inbox UML float-to-int size operand corrected (SIZE_SHORT/SIZE_DOUBLE)
5cca9a22a45 docs inbox UML shift/rotate section
4a7c4246575 docs inbox UML SEXT documented
109c3705ffe noise - typo fixes across techspecs
3904f0778ab docs inbox UML multiply/divide + simplification rules
f7731929a75 new logging device_network_interface::log_bytes() replaces per-device packet dumpers
21f7e136205 docs inbox UML ROLC/RORC etc. documented
20a61a456e9 deprecates inbox PORT_OPTIONAL / FIELD_FLAG_OPTIONAL removed
bd303b15dcf deprecates inbox PORT_ROTATED / FIELD_FLAG_ROTATED removed
18e587c5e6a noise - log_bytes takes const u8 *
996b632bed8 noise - dirom member reorder
cee362f88c7 docs inbox UML condition codes table
13c25cb2aff docs inbox UML simplification-rule sections
27e7bbb1f0c docs inbox UML SETFLGS documented
af47c272d6c noise - util AES for pgm3
09b00ba83b5 docs inbox UML flag masks, GETFLGS
50c45145df8 noise - debugger memdump
6d4ccfd688c noise - RGB utility implementations consolidated; rgbaint_t API unchanged
d4be3bb639e noise - static_assert/debug checks on device type definitions
8a74b97658c new inbox UML BFXU/BFXS/DBFXU/DBFXS bit-field extract
42e4078725d docs inbox layouts: text align="3" stretches to bounds
3071a892c39 migration object-finders region/RAM storage aligned; casts of base() replaced by as_u16()/typed region_ptr/pointer<T>()
7947644129e deprecates object-finders running_machine::driver_data<T>() removed
3b565c05d0f docs inbox layouts: text/counter elements use the artwork font option
550751c0e4f noise - doc wording tidy, version bump
d91971dc232 noise - typo
b2cffd54832 noise - .lay text bounds narrowed for wide fonts
2209d46c947 noise - DRC cache W^X option
cf70b0c19d9 noise - inputdev lightgun reload hack removed (internal)
63a40168225 new address-maps logical (MMU) address spaces: memory_logical_space_config()
7bc324298d8 docs inbox UML_CALLHc argument order corrected
70cdcb69c11 noise - noscreens.lay message
67148757304 noise - noscreens.lay message
a7b3ce33ccf docs inbox UML: no HASH in invariant code blocks
879bcb8b8cb deprecates inbox IPT_TILT1..4 removed; IPT_GAMBLE_DOOR + IPT_INTERLOCK -> IPT_DOOR
e6bc966bed6 deprecates inbox ROM_OPTIONAL [[deprecated]]; romentry.h macros -> constexpr
da5e44f6072 noise - typo fix
bb5a4f4c784 noise - constexpr linkage, reserved names in palette.h
5345617fbc2 noise - rewording of the HASH note
4c56746809d noise - srcclean
3c6ffd84b0a noise - e132xs UML logging
1f7fa43c3d2 docs inbox UML CALLC may take any single pointer/reference parameter (uml_instructions.rst); CPU-core only
825f7de5e3a noise - screen configure bug fix
dde7a2021e4 new inbox single-argument tilemap set_scrollx/set_scrolly now fill every scroll row/column, not just row 0
237d736a310 new inbox device_slot_interface::set_options(opts, dflt, fixed) helper (~240 slot headers); IPT_GAMBLE_SERVICE removed (use IPT_SERVICE1)
b55ba81d2a4 migration inbox C++20 fixes: no arithmetic between different enum types / enum and float; anonymous-enum constants become static constexpr
4044303cd76 noise - traits structs internal to DEFINE_DEVICE_TYPE/GAME macros
eea4b471906 noise - C++20/GCC 11 switch; char8_t shims keep u8"" names working
93d2609de53 noise - transparent string maps in core
b42e52e6010 noise - delegate ABI hack removed
a511e3a4e81 noise - clang-cl flags; unused sound.h declarations
3f75ea4e1c3 noise - device_t base ctor string_view tag; save error reporting (already a mame-review L-1/L-2/D-6 source)
7ff17615ba9 noise - i686 DRC/Altivec/SysV removed
6014a2e975d noise - build docs only
56ea076a1fd new inbox screen_device::update_partial(vpos, hpos); update_now() returns bool and goes through it
db1e21d2dcf new address-maps remove_addrmap(AS_x) replaces set_addrmap(AS_x, address_map_constructor()); 9 drivers converted
3dfb72cb624 noise - UI menu options
d6dd21e2013 noise - UI media menus; coinage string fix
5ccf74d3c1f deprecates inbox driver_device device_start/device_reset_after_children/device_add_mconfig/device_rom_region/device_input_ports now final
b76d72b20cc deprecates inbox count_leading_zeros/ones_32/64, population_count_32/64 removed from eminline.h for <bit>
1da6d28d1bf noise - enable_if to requires inside emumem_hedp/romload (scope superseded by b946df69fcc)
b946df69fcc new inbox requires clauses replace enable_if across emu/util; C++17 dropped
119c14d105c noise - GCC workaround
d0fdc637eee noise - GCC workaround
bdf56c6ae80 migration inbox M_PI etc. replaced by std::numbers (none left in src/mame, src/devices)
b90dab77c9a new object-finders output finders initialised from name arrays; get_value/set_value [[deprecated]] (captured)
7fe1dda1795 noise - dangling reference fix
afd3f3da405 migration inbox endianness_t = std::endian; BYTE_XOR_* need "endianness.h", u2f/f2u/DEGREE_TO_RADIAN need "corefloat.h"; endianness_t no longer saveable
b00141d092f noise - follow-up
f4f6f34f2a8 deprecates object-finders output finders self-resolving, get/set_value removed, finders non-copyable (captured)
a60cb3f24d3 noise - GCC workaround
fca00cace9e migration inbox no default args on protected ctors; public standard-signature ctor required; no default zero clock for clocked devices or clock-supplying slots
25062e76677 noise - delegate.h requires placement
5193d37fa8b new object-finders device-scoped output names (captured); input.h dropped from emu.h (headers finding)
327f08d41b0 noise - libstdc++ fix
1ace0bc4617 noise - libstdc++ fix
cbe97600edb docs object-finders object_finders.rst output section updated (captured as T2)
e28f04501d7 migration inbox layouts: deprecated <reel> components replaced by elements with yscroll (component removed in e509909bd59)
58fca9a8a20 docs - AI-assistance disclosure policy; already in SKILL.md and mame-review S-1
869b1239acf noise - header hygiene
44801e066b2 noise - header hygiene
741da632a54 new inbox palette_device::BGR_222 for 6-bit BBGGRR palettes
f624932c2be new inbox corefloat.h gains fpmod1/fmaprange
85a96b3844f deprecates interrupts-devcb set_input_line_vector/set_input_line_and_vector [[deprecated]] (captured)
9119c7237a9 new inbox gfx_element::decode_all() replaces get_data(i) predecode loops
6deb9130b69 migration sound-streams sound.h, video.h dropped from emu.h (sound.h captured; video.h in headers finding)
e0adb59e6ad docs inbox cxx.rst section recommending count_leading_zeros_32/rotl_32 etc. removed
774a180df2b new inbox screen_device split: SCREEN_TYPE_* gone; SCREEN, .set_lcd(), VECTOR, SCREEN_SVG; device_video_output_interface
29f9837d9b1 noise - build fix
63c2ec0ccfe deprecates inbox rotl_32/rotr_32/rotl_64/rotr_64 removed for std::rotl/rotr
4873b416e7e new inbox frame period is attotime: configure(w,h,visarea,attotime), set_refresh(attotime); refresh_attoseconds() removed
bb6e4fd791c noise - 3rdparty glm
97c42b0fe0a noise - vector renderer bug fix
89e00b9bcdb noise - 3rdparty asio
c0ea23d6504 noise - Lua output enumeration
c7a92906e89 noise - bgfx vector CRT docs (user-facing)
fd6e7a50a04 migration object-finders root_device().memregion(subtag(X).c_str())->base() in cards replaced by required_region_ptr
ad09989a8c3 new inbox screen().has_been_setup() replaces !configured()/!refresh_attoseconds() in devices that supply default timings
c690a9ed43f new inbox floppy write_start/write_flux_change/write_end/write_flush replace write_flux(...); documented in floppy.rst
30c82d39370 noise - util cleanups
bcb5cacdf76 noise - PKZIP writer
ffdbdc702c3 noise - memory view validation fix
4f44364b25e new logging LOG/LOGMASKED dispatch from interface mixins (captured)
4bb0fa2bbc7 deprecates inbox emu_file::puts/printf/vprintf removed; use util::owritestream
cb329abc566 noise - crc16_creator initial value
1a8267fa579 noise - vtlb_flush_fixed, one CPU family
ab1d1b5616e noise - DRC retry_access pointer
0965d4eaa48 noise - network interface cancel_send/receive
f11e04e317d deprecates inbox driver_start/driver_reset removed; state_add takes any string type
8089ec90d35 migration inbox state_add(..., string_format(...)) without .c_str() across CPU cores
ab1bc044b6d noise - 3rdparty AES
