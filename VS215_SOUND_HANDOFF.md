# Handoff: vs215 (Step 1.5) — sonido

## Objetivo
Hacer que `ROMS/vs215.zip` (Virtua Striker 2, Step 1.5) **se oiga** al lanzarlo. El usuario no le importa el ROM de Step 2.0 (`vstriker2`). Compilar SIEMPRE con `build_msvc.bat`.

## Estado actual (verificado)
- vs215.zip **carga y corre**: `VF3_HIDDEN=1 ./build/bin/vf3run.exe "ROMS/vs215.zip" --frames 4000 --wav <ruta>` → "Virtua Striker 2 (Step 1.5) ('vs215')", PC avanza, exit 0.
- **PERO el WAV sale en silencio** (peak=0, 0% de samples >16) y `VF3_MIDI_LOG` registra **solo 1 byte MIDI en 2000 frames**.
- Conclusión: NO es un mute ni una placa mal conectada. El juego **no escribe MIDI** a la placa de sonido (se queda en attract/título sin emitir audio, o el driver de sonido de VS215 no se inicializa).

## Cambios ya aplicados (compilados, build exit 0)
1. `src/machine/profile.h` — declarado `extern const Profile ... VS215;`
2. `src/machine/profile.cpp`:
   - `VS215_ROMS[]`: 4 CROM propios (`epr-19897.20`..`epr-19900.17`, 512KB c/u, offsets 0/2/4/6, chunk 8 stride 2), banked CROM (mpr-19769..19784), VROM (mpr-19787..19802), **programa de sonido `epr-19807.21`** (CRC 0x9641CBAF, ROM_SOUND) y **samples `mpr-19785.22` + `mpr-19786.24`** (ROM_SAMPLES, offsets 0 y 0x400000).
   - Perfil `VS215`: `{ 0x15, 0, false, { 0x200000, 0x4000000, 0x2000000, 0x80000, 0x800000 } }` (stepping 0x15, sin security chip, CROM 2MB).
   - Registrado en `PROFILES[]`: `{ &VF3_REV_D, &VF3_TB, &FV2_REV_A, &FV2O_REV, &SRALLY2, &VSTRIKER2, &VS215, nullptr }`.
3. `src/machine/model3.cpp` — el parche de tasa de frames de vstriker2 ahora también aplica a `vs215` (`target_hz = (set=="vstriker2"||set=="vs215") ? 115.048320f : 57.524160f`).
4. `src/host/main.cpp` — los dos parches de host de vstriker2 (GPU 3D + frame pacing) ahora también cubren `vs215`.

## Cómo funciona la cadena de sonido (para orientarse)
- El juego escribe bytes MIDI al puerto `0xF0000008` → `Model3::write8` los mete en `board.midi` (deque, `src/machine/model3.h:542`).
- El host (`src/host/main.cpp`) y el runner (`tools/vf3run.cpp`) drenan `board.midi` → `sound.midi_in(byte)` → `SoundBoard::run()` (68000 + 2 SCSP) → PCM.
- `SoundBoard` se conecta a `board.sound_rom` (programa 68000) y `board.samples` (`src/machine/model3.cpp:408-409`, llenados desde `romset.cpp:302-303`).
- `sound.driver_known = board.set == "vf3"` (runner, línea ~345): para vs215 es **false** → la separación música/efectos no se aplica (ambos volúmenes juntos). No debería bloquear el audio, pero revisarlo si hace falta.
- `mute_game_midi` (`model3.h:548`) está en `false` por defecto; el host lo setea desde `port_sound()` (main.cpp:6757).

## Pruebas ya hechas (resultados)
- `--frames 600 --wav`: WAV 1.8MB, **peak=0**.
- `--frames 4000 --wav`: dur 69.5s, **peak=0**.
- `VF3_MIDI_LOG` con `--frames 2000`: **1 byte MIDI** en todo el run.

## Qué falta / próximos pasos (a decidir en la nueva sesión)
1. **Forzar un estado con audio**: el runner tiene `VF3_STAGE=n` (fuerza arena 1-12), `VF3_FREE_PLAY`, `VF3_POKE=addr=value`, y `--script FILE`. Probar a meter el juego a selección/partido y volver a capturar WAV + MIDI_LOG.
2. **Verificar que el programa de sonido 68000 corre**: `VF3_DUMP_SOUND_RAM=f` (dump RAM de los SCSP), `VF3_SCSP_WLOG`, `VF3_KEYON_LOG=1`. Si la RAM de sonido no cambia, el 68000 no está ejecutando el driver.
3. **Revisar `driver_known=false`**: si VS215 usa un driver distinto al de VF3, la lectura de fichas/voice records puede estar mal; pero el audio base debería salir igual.
4. **Comparar con vstriker2 (Step 2.0)**: ¿ese ROM sí produce sonido en este build? Si sí, comparar qué diferencia hay entre los dos perfiles (mismo board, mismo sound program/samples) para aislar la causa.
5. **Confirmar en el host real** (no solo vf3run): lanzar `jugar-vs215.bat` / `build/bin/vf3.exe` con vs215.zip y oír. El runner es la vía rápida de diagnóstico, pero el objetivo final es el host.

## Comandos útiles
```bash
cd "C:\ai\recomp\Trabajorecomp\vf3-recomp-worksnosound-agent"
# build (obligatorio)
cmd /c "build_msvc.bat > build_out.log 2>&1"
# test headless con audio
VF3_HIDDEN=1 ./build/bin/vf3run.exe "ROMS/vs215.zip" --frames 4000 --wav "C:/Users/Compu/AppData/Local/Temp/vs215.wav"
# MIDI log
VF3_HIDDEN=1 VF3_MIDI_LOG="C:/Users/Compu/AppData/Local/Temp/midi.log" ./build/bin/vf3run.exe "ROMS/vs215.zip" --frames 2000 --wav "C:/Users/Compu/AppData/Local/Temp/vs215.wav"
# check peak del WAV
python -c "import wave,struct; w=wave.open('C:/Users/Compu/AppData/Local/Temp/vs215.wav'); d=w.readframes(w.getnframes()); p=max(abs(struct.unpack('<h',d[i:i+2])[0]) for i in range(0,len(d),2)); print('peak',p)"
```

## Notas
- El usuario prefiere trabajo minimalista y enfocado: no montar infraestructura innecesaria, solo lo estrictamente requerido.
- No recapitular en exceso; actuar directamente.
- La carpeta del proyecto es `C:\ai\recomp\Trabajorecomp\vf3-recomp-worksnosound-agent`.
