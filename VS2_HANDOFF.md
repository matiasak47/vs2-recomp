# VS2 (Virtua Striker 2) — handoff para sesión nueva

Objetivo: que `fvipers2` (este proyecto, branch `fv2`) reconozca y cargue **Virtua Striker 2**
como perfil nuevo desde `ROMS/vstriker2.zip`, sin romper VF3 / VF3TB / FV2 / Sega Rally 2.

## Estado actual (verificado)
- Build OK: `build_msvc.bat` termina `EXIT=0`. Binarios: `build/bin/vf3.exe`, `build/bin/vf3run.exe`.
- Bloqueo: el loader NO reconoce `vstriker2.zip` como set. Cae a "set incompleto / no conocido".
- Arquitectura actual = **Profile** (`src/machine/profile.h` + `profile.cpp`, `romset::load(path, profile)`).
  NO es la arquitectura vieja de `SETS[]`. El port debe adaptarse a Profile.

## LA CLAVE (lead de oro) — ya existe una VS2 que funciona
Proyecto previo: `C:\ai\recomp\Trabajorecomp\vs2-recomp-project_casiperfecto`
- `src/machine/romset.cpp`:
  - Tabla `VS2_DATA[]` (líneas ~250-268): 16 ROMs de CROM banked + 1 programa de sonido. CRCs verificados.
  - Entrada del set (~línea 298):
    `{ "vstriker2", "Virtua Striker 2", 0x20, 0x29260E96, false, true, { 0x800000, 0x4800000, 0x40000000, 0x80000, 0 }, nullptr, 0, LIST(VS2_DATA) }`
    (stepping 0x20 = Step 2.0; crypto_key 0x29260E96; gzip_program=false; skip_crc=true)
  - Detección por nombre (~línea 408): `if (path.find("vstriker2") != npos)` → elige el set por nombre y salta el scan de CRC.
  - `z.skip_crc = (s->name == "vstriker2")` (~línea 427): los headers locales del zip traen un CRC placeholder (0x44363176); hay que confiar en los chips.
  - CROM fijo desde archivo (~líneas 464-471): lee `C:\ai\recomp\Trabajorecomp\vs2_rom\crom_fixed.bin` (8 MB, EXISTE) y lo usa como `res.crom`.
- El CROM fijo ya está en disco: `C:\ai\recomp\Trabajorecomp\vs2_rom\crom_fixed.bin` (8388608 bytes).

## Fuente autoritativa del layout de ROMs
Supermodel: `C:\ai\recomp\supermodel-ref\Config\Games.xml`, `<game name="vs2">` (líneas 2757-2833).
Los CRCs de esa entrada coinciden EXACTAMENTE con los del zip (verificados):
- crom (programa, fijo): epr-20467.17=0x25D7AE73, epr-20468.18=0xF0F0B6EA, epr-20469.19=0x9D7521F6, epr-20470.20=0x2F62B292
- banked_crom: mpr-19769.1..mpr-19784.16 (16 × 4 MB)
- vrom: mpr-19787.26..mpr-19802.41 (16 × 2 MB)
- sound_program: epr-19807.21=0x9641CBAF
- sound_samples: mpr-19785.22=0xE7D190E3, mpr-19786.24=0xB08D889B
- driveboard_program: epr-18022.ic2 (NO está en el zip; required=false)

El zip `ROMS/vstriker2.zip` tiene 39 entradas = 4 crom + 1 sound_prog + 16 banked + 2 samples + 16 vrom. ✓

## PASOS A SEGUIR (en este proyecto, arquitectura Profile)
1. En `src/machine/profile.cpp`: definir la tabla de ROMs de VS2 (`VS2_ROMS[]`) con los CRCs de arriba
   (bancos CROM + VROM + SOUND + SAMPLES), y un `const Profile VS2 = {...}` modelado sobre `SRALLY2`
   (líneas 349-363): stepping 0x20, crypto_key 0x29260E96, gzip_program=false.
   - Regiones (`board.region[]`): CROM, BANKED, VROM, SOUND, SAMPLES con los tamaños que el set llena.
2. Añadir `&VS2` a `PROFILES[]` (línea 365).
3. En `src/machine/romset.cpp`:
   - Detección: si la ruta contiene "vstriker2", elegir el perfil por nombre (como hace el proyecto previo) en vez de depender del scan de CRC.
   - `skip_crc` para vstriker2 (headers locales con CRC placeholder).
   - CROM fijo: leer `C:\ai\recomp\Trabajorecomp\vs2_rom\crom_fixed.bin` como `res.crom` en vez de interleavear los 4 epr del zip.
4. Verificar que `Model3::load()` ya maneja Step 2.0 (stepping 0x20 → model 0x106, cpu.configure(0x00071202,5,165000000,0x60000000), ppc_hz=166000000). Ya está.
5. Build: `cmd /c "build_msvc.bat" > build_out.log 2>&1` (background; tarda >420 s en foreground).
6. Probar: `VF3_HIDDEN=1 build/bin/vf3run.exe "ROMS/vstriker2.zip" --frames 5`.

## PREGUNTA ABIERTA (verificar antes de dar por bueno)
El proyecto previo `casiperfecto` define VS2_DATA SOLO con banked CROM + sound program; NO incluye
vrom ni samples en su tabla, aunque el zip SÍ los trae. Por eso ese build probablemente corre la CPU/recomp
pero sin texturas/samples completos. Al portar a este proyecto, AÑADIR las entradas de vrom y samples
(CRCs verificados arriba) para que sea un set completo. Confirmar con `--shots` (screenshots) que el juego
renderiza, no solo que la CPU corre.

## Notas
- NO usar `build_msvc - Copy.bat` (el usuario lo descartó).
- `vs215.zip` es Step 1.5 (otro set, fuera de este objetivo).
- Parche de frustum ya presente en `src/video/r3d_scene.cpp:214` para vstriker2 (Step 2.0 híbrido) — local, no commitado.
