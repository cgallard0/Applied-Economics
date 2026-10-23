/*******************************************************************************
							    Problem Set 5
                              Efectos fijos

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file:
1) Estima la especificación base por MCO.
2) Estima el modelo con distintas combinaciones de efectos fijos (household,
   year, village, village x year).
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout outreg2 ftools reghdfe {
	cap which `pkg'
	if _rc ssc install `pkg'
}

use "$input/microcredit.dta", clear

replace year = 1991 if year==0
replace year = 1998 if year==1
xtset nh year

*==============================================================================*

* 1) basic model

gen log_exptot = log(exptot)
label var log_exptot "Log Expenditure"
label var dfmfd "Female participation"

eststo clear
eststo base: reg log_exptot dfmfd
outreg2 using "$output/Tabla 1.doc", dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, No, Year fixed effects, No, Controls, No) replace
esttab base using "$output/Tabla 1.tex", replace label booktabs se b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) r2 nonotes nomtitles

*==============================================================================*

* 2) fixed effects

* identificadores de las celdas village x year y household x year
egen village_year = group(village year)
egen hh_year = group(nh year)

*(a) household fixed effects
eststo m1: reghdfe log_exptot dfmfd, absorb(nh)
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, Yes, Year fixed effects, No, Village x year fixed effects, No) ///
addnote("Column (1): household FE. Column (2): year FE. Column (3): village FE. Column (4): village and household FE. Column (5): year and household FE. Column (6): year and village FE. Column (7): village x year FE. Column (8): village x year and household FE. Household x year FE cannot be estimated (one observation per cell).") replace

*(b) year fixed effects
eststo m2: reghdfe log_exptot dfmfd, absorb(year) 
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, No, Year fixed effects, Yes, Village x year fixed effects, No) append

*(c) village fixed effects
eststo m3: reghdfe log_exptot dfmfd, absorb(village)
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, Yes, Household fixed effects, No, Year fixed effects, No, Village x year fixed effects, No) append

*(d) village and household fixed effects
* se puede correr, pero los FE de village son redundantes: cada hogar está en una
* sola village, así que village FE es una combinación lineal de household FE.
* El resultado es idéntico al de household FE.
eststo m4: reghdfe log_exptot dfmfd, absorb(village nh)
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, Yes, Household fixed effects, Yes, Year fixed effects, No, Village x year fixed effects, No) append

*(e) year and household fixed effects
eststo m5: reghdfe log_exptot dfmfd, absorb(year nh) 
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, Yes, Year fixed effects, Yes, Village x year fixed effects, No) append

*(f) year and village fixed effects
eststo m6: reghdfe log_exptot dfmfd, absorb(year village) 
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, Yes, Household fixed effects, No, Year fixed effects, Yes, Village x year fixed effects, No) append

*(g) village x year fixed effects
eststo m7: reghdfe log_exptot dfmfd, absorb(village_year)
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, No, Year fixed effects, No, Village x year fixed effects, Yes) append

*(h) household x year fixed effects: NO se puede estimar. Hay una sola
* observación por hogar y año, así que los efectos fijos absorben toda la
* variación (todas las observaciones son singletons).
cap noisily reghdfe log_exptot dfmfd, absorb(hh_year)

*(i) village x year fixed effects and household fixed effects
eststo m8: reghdfe log_exptot dfmfd, absorb(village_year nh)
outreg2 using "$output/Tabla 2.doc", keep(dfmfd) dec(3) label ///
addtext(Village fixed effects, No, Household fixed effects, Yes, Year fixed effects, No, Village x year fixed effects, Yes) append

* indicadores de efectos fijos para la tabla LaTeX
estadd local fe_h "Yes" : m1 m4 m5 m8
estadd local fe_h "No"  : m2 m3 m6 m7
estadd local fe_y "Yes" : m2 m5 m6
estadd local fe_y "No"  : m1 m3 m4 m7 m8
estadd local fe_v "Yes" : m3 m4 m6
estadd local fe_v "No"  : m1 m2 m5 m7 m8
estadd local fe_vy "Yes" : m7 m8
estadd local fe_vy "No"  : m1 m2 m3 m4 m5 m6

esttab m1 m2 m3 m4 m5 m6 m7 m8 using "$output/Tabla 2.tex", replace label booktabs ///
	keep(dfmfd) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) nonotes nomtitles ///
	stats(fe_h fe_y fe_v fe_vy N r2, fmt(0 0 0 0 %9.0fc 3) ///
	labels("Household FE" "Year FE" "Village FE" "Village x year FE" "Observaciones" "R-cuadrado"))
