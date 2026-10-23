# Economía Aplicada (E178) — Universidad de San Andrés, 2024

Problem sets de Economía Aplicada resueltos en Stata, con los informes escritos en LaTeX.

**Integrantes:** Juan Batalla, Nina Di Costanzo Pereira, Catalina Gallardo e Ignacio Yenarópulos.

## Estructura

Cada problem set tiene su propia carpeta (`PS1` a `PS11`) con la misma estructura:

```
PSn/
├── documents/   consigna (PDF), paper de referencia (si hay) e informe (.tex y .pdf)
├── input/       bases de datos originales
├── output/      tablas (.tex, .rtf, .doc) y figuras (.png) generadas por el do-file
└── programs/    código en Stata (psn.do y, si hace falta, ados auxiliares)
```

Los datos de `input/` no se modifican: todo lo que genera el código se guarda en `output/`.
En PS3 y PS9 la carpeta `input/` está vacía porque los datos se simulan dentro del do-file.

## Contenido

| PS | Tema | Datos | Paper en `documents/` |
|----|------|-------|-------|
| PS1 | Repaso y primeros pasos en Stata (MCO) | `data_russia.dta` | — |
| PS2 | Multiple hypothesis testing (Bonferroni, Holm, q-valores) | `measures.dta` | Attanasio et al. (2020) |
| PS3 | Sesgos e imprecisión (simulaciones) | simulados | — |
| PS4 | Variables instrumentales | `poppy.dta` | *Following the poppy trail* |
| PS5 | Efectos fijos | `microcredit.dta` | — |
| PS6 | Diferencias en diferencias escalonadas (TWFE, Callaway–Sant'Anna, BJS) | `castle.dta` | Cheng y Hoekstra (2013) |
| PS7 | Inferencia con clusters (cluster-robust, wild bootstrap, ART) | `base01.dta` | Angrist y Lavy (2009) |
| PS8 | Control sintético (homicidios en São Paulo) | `.csv` en `input/` | Freire (2018) |
| PS9 | Power calculations (simulaciones) | simulados | — |
| PS10 | Regresión discontinua (regla de Maimónides) | `grades5.dta` | — |
| PS11 | Matching y propensity score | `base_censo.dta` | — |

En `PS8/documents/homicides-sp-synth-master` está el paquete de replicación original del paper (en R), solo como referencia.

## Cómo correr el código

1. Abrir `PSn/programs/psn.do` en Stata.
2. Completar la ruta a la carpeta del problem set en la línea del directorio, por ejemplo:
   ```stata
   global main "C:/Users/usuario/Economía Aplicada/PS1"
   ```
   (en PS2 la línea es `gl main ""`). Las globales `input`, `output` y `programs` se arman a partir de `main`.
3. Correr el do-file completo. Los paquetes que hacen falta (`estout`, `outreg2`, `reghdfe`, `boottest`, `csdid`, `did_imputation`, `synth`, `rdrobust`, `rddensity`, `psmatch2`, etc.) se instalan automáticamente si no están.

Notas:
- PS7 usa `art.ado`, que está en `PS7/programs/` y se carga desde el do-file.
- PS8 (control sintético con placebos y leave-one-out) tarda varios minutos.

## Cómo compilar los informes

Los `.tex` de `documents/` leen las tablas y figuras de `../output/` y el código de `../programs/` (se incluye como apéndice). Por eso:

- **Local:** compilar con `pdflatex` desde la carpeta `documents/`, manteniendo la estructura del PS.
- **Overleaf:** subir la carpeta completa del problem set (con `documents`, `output` y `programs`) y poner como documento principal el `.tex` de `documents/`.

Si se vuelve a correr el código, alcanza con recompilar el `.tex` para que el informe tome las tablas y figuras nuevas.
