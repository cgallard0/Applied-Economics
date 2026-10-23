/*******************************************************************************
							    Problem Set 4
                          Variables instrumentales

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file:
1) Construye Chinese presence.
2) Hace la estadística descriptiva (Tabla 1 del paper).
3) Replica por MCO las columnas 3 a 6 de la Tabla 5 (efectos fijos por estado,
   errores clusterizados por estado y p-valores de wild bootstrap).
4) Estima por 2SLS las Tablas 7 y 8 (con el F de la primera etapa).
5) Realiza el test de endogeneidad de la presencia de cárteles.
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout boottest {
	cap which `pkg'
	if _rc ssc install `pkg'
}

use "$input/poppy.dta", clear

*==============================================================================*

* 1) variable "chinese presence"

*es una variable dummy que toma valor 1 si la población china en 1930 es mayor a cero, 0 si no
gen chinese_presence = .
replace chinese_presence = 1 if chinos1930hoy > 0 & !missing(chinos1930hoy)
replace chinese_presence = 0 if chinos1930hoy == 0
label var chinese_presence "Chinese presence"

*==============================================================================*

* 2) descriptive statistics

*dividimos por 1000 para expresarlo como miles
gen pob_2015 = POB_TOT_2015/1000
gen super_km = superficie_km/1000
gen pob_1930 = pob1930cabec/1000

label var cartel2010 "Cartel presence 2010"
label var cartel2005 "Cartel presence 2005"
label var chinos1930hoy "Chinese population"
label var IM_2015 "Marginalization"
label var Impuestos_pc_mun "Per capita tax revenue"
label var n_index_p "Laakso and Taagepera index"
label var dalemanes "German presence"
label var tempopium "Poppy suitability"
label var distancia_km "Distance to U.S. (km)"
label var distkmDF "Distance to Mexico City (km)"
label var mindistcosta "Distance to closest port"
label var capestado "Head of state"
label var pob_2015 "Population in 2015 (in 000)"
label var super_km "Surface (000 km2)"
label var TempMed_Anual "Average temperature (Celsius)"
label var PrecipAnual_med "Average precipitation (mm)"
label var growthperc "Local population growth (1920-30)"
label var pob_1930 "Population in 1930 (in 000)"

* cada variable se resume con todas sus observaciones válidas (se reporta N)
estpost summarize cartel2010 cartel2005 chinese_presence chinos1930hoy IM_2015 Impuestos_pc_mun n_index_p dalemanes tempopium distancia_km distkmDF mindistcosta capestado pob_2015 super_km TempMed_Anual PrecipAnual_med growthperc pob_1930
esttab using "$output/Tabla 1.rtf", cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
collabels("N" "Mean" "SD" "Min" "Max") nomtitle nonumber noobs replace label 
esttab using "$output/Tabla 1.tex", cells("count(fmt(%9.0fc)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
collabels("N" "Media" "Desvío" "Mín." "Máx.") nomtitle nonumber noobs replace label booktabs

*==============================================================================*

* 3) regressions (Tabla 5, columnas 3 a 6)

drop if estado == "Distrito Federal"

global controls "dalemanes tempopium TempMed_Anual PrecipAnual_med super_km pob_1930 distancia_km distkmDF mindistcosta capestado"

* columnas: (1) 2010 sin controles; (2) 2010 con controles; (3) 2005 sin controles; (4) 2005 con controles
eststo clear
local c1 ""
local c2 "$controls"
local j = 0
foreach y in cartel2010 cartel2005 {
	forvalues k = 1/2 {
		local ++j
		regress `y' chinese_presence `c`k'' i.id_estado, cluster(id_estado)
		est store ols_`j'
		boottest chinese_presence, reps(999) cluster(id_estado) seed(12345) nograph
		estadd scalar wild_p = r(p) : ols_`j'
		estadd local fe "Yes" : ols_`j'
		if `k' == 1 estadd local ctrl "No" : ols_`j'
		else estadd local ctrl "Yes" : ols_`j'
	}
}

esttab ols_1 ols_2 ols_3 ols_4 using "$output/Tabla 2.rtf", replace se label ///
    keep(chinese_presence) star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) ///
	stats(wild_p fe ctrl N_clust N, fmt(3 0 0 0 0) label("Wild bootstrap p-value" "State dummies" "Controls" "Clusters" "Observations")) ///
	addnotes("Wild-bootstrapped p-values (999 replications). The unit of observation is a municipality. The unit of cluster is a state. All models are estimated using Ordinary Least Squares. The set of controls includes German presence, Poppy suitability, Average temperature, Average precipitation, Surface, Population in 1930, Distance to U.S., Distance to Mexico City, Distance to closest port, and Head of state.")
esttab ols_1 ols_2 ols_3 ols_4 using "$output/Tabla 2.tex", replace se label booktabs nonotes ///
    keep(chinese_presence) star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) ///
	stats(wild_p fe ctrl N_clust N, fmt(3 0 0 0 %9.0fc) label("Wild bootstrap p-valor" "Efectos fijos por estado" "Controles" "Clusters" "Observaciones"))
	
*==============================================================================*

* 4) iv estimates

label var cartel2010 "Cartel presence"

*tabla 7
* especificaciones: (1) sin controles; (2) especificación básica; (3) excluye
* municipios a menos de 100 km de EE.UU.; (4) excluye Sinaloa; (5) agrega growthperc
local c1 ""
local c2 "$controls"
local c3 "$controls"
local c4 "$controls"
local c5 "$controls growthperc"
local s1 ""
local s2 ""
local s3 "if distancia_km > 100"
local s4 `"if estado != "Sinaloa""'
local s5 ""

forvalues j = 1/5 {
	ivregress 2sls IM_2015 `c`j'' i.id_estado (cartel2010 = chinese_presence) `s`j'', cluster(id_estado)
	est store iv_`j'
	cap drop insample
	gen insample = e(sample)
	boottest cartel2010, reps(999) cluster(id_estado) seed(12345) nograph
	estadd scalar wild_p = r(p) : iv_`j'
	* F de la primera etapa (instrumento excluido), misma muestra
	quietly regress cartel2010 chinese_presence `c`j'' i.id_estado if insample, cluster(id_estado)
	test chinese_presence
	estadd scalar ftest = r(F) : iv_`j'
	estadd scalar fpval = r(p) : iv_`j'
	estadd local fe "Yes" : iv_`j'
	if `j' == 1 estadd local ctrl "No" : iv_`j'
	else estadd local ctrl "Yes" : iv_`j'
}

esttab iv_1 iv_2 iv_3 iv_4 iv_5 using "$output/Tabla 3.rtf", replace se label ///
    keep(cartel2010) star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) ///
	stats(wild_p ftest fpval fe ctrl N_clust N, fmt(3 2 3 0 0 0 0) label("Wild bootstrap p-value" "F-test (first stage)" "p-value F" "State dummies" "Controls" "Clusters" "Observations")) ///
	addnotes("Wild-bootstrapped p-values (999 replications). The unit of observation is a municipality. The unit of cluster is a state. All models are estimated using Two Stages Least Squares. Cartel presence is instrumented using Chinese presence. F-test is the F-test of excluded instruments. In Columns (2) to (4) the set of controls includes German presence, Poppy suitability, Average temperature, Average precipitation, Surface, Population in 1930, Distance to U.S., Distance to Mexico City, Distance to closest port, and Head of state. Column (5) further controls for Local population growth. Column (3) excludes those municipalities located within 100 km from the U.S. border. Column (4) excludes municipalities located in the state of Sinaloa.")
esttab iv_1 iv_2 iv_3 iv_4 iv_5 using "$output/Tabla 3.tex", replace se label booktabs nonotes ///
    keep(cartel2010) star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) ///
	stats(wild_p ftest fpval fe ctrl N_clust N, fmt(3 2 3 0 0 0 %9.0fc) label("Wild bootstrap p-valor" "F primera etapa" "p-valor F" "Efectos fijos por estado" "Controles" "Clusters" "Observaciones"))

*tabla 8
local j = 5
foreach y in ANALF_2015 SPRIM_2015 OVSDE_2015 OVSEE_2015 OVSAE_2015 VHAC_2015 OVPT_2015 PL5000_2015 PO2SM_2015 {
	local ++j
	ivregress 2sls `y' $controls i.id_estado (cartel2010 = chinese_presence), cluster(id_estado)
	est store iv_`j'
	boottest cartel2010, reps(999) cluster(id_estado) seed(12345) nograph
	estadd scalar wild_p = r(p) : iv_`j'
	estadd local fe "Yes" : iv_`j'
	estadd local ctrl "Yes" : iv_`j'
}

esttab iv_6 iv_7 iv_8 iv_9 iv_10 iv_11 iv_12 iv_13 iv_14 using "$output/Tabla 4.rtf", replace se label ///
    keep(cartel2010) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
	stats(wild_p fe ctrl N_clust N, fmt(3 0 0 0 0) label("Wild bootstrap p-value" "State dummies" "Controls" "Clusters" "Observations")) ///
	addnotes("Wild-bootstrapped p-values (999 replications). The unit of observation is a municipality. The unit of cluster is a state. All models are estimated using Two Stages Least Squares. Cartel presence is instrumented using Chinese presence. The set of controls includes German presence, Poppy suitability, Average temperature, Average precipitation, Surface, Population in 1930, Distance to U.S., Distance to Mexico City, Distance to closest port, and Head of state.")
esttab iv_6 iv_7 iv_8 iv_9 iv_10 iv_11 iv_12 iv_13 iv_14 using "$output/Tabla 4.tex", replace se label booktabs nonotes ///
    keep(cartel2010) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
	mtitles("Illiteracy" "Without primary" "Without toilet" "Without electricity" "Without water" "Overcrowding" "Earthen floor" "Small localities" "Low salary") ///
	stats(wild_p fe ctrl N_clust N, fmt(3 0 0 0 %9.0fc) label("Wild bootstrap p-valor" "Efectos fijos por estado" "Controles" "Clusters" "Observaciones"))

*==============================================================================*

* 5) tests (especificación básica)

* (a) Exogeneidad del instrumento: NO se puede testear. Hay un solo instrumento
*     para una sola variable endógena (modelo exactamente identificado), así que
*     no hay restricciones de sobreidentificación: los tests de Sargan/Hansen
*     requieren más instrumentos que variables endógenas. Además, los residuos de
*     2SLS son ortogonales al instrumento por construcción, por lo que regresar
*     los residuos contra el instrumento no aporta información.

* (b) Endogeneidad de cartel presence, suponiendo que el instrumento es exógeno:
*     test de Hausman (Durbin-Wu-Hausman). H0: cartel presence es exógena (OLS y
*     2SLS son ambos consistentes). Usamos la versión robusta a clusters.
ivregress 2sls IM_2015 $controls i.id_estado (cartel2010 = chinese_presence), cluster(id_estado)
estat endogenous

*     Lo mismo "a mano" (función de control): se agrega el residuo de la primera
*     etapa a la ecuación estructural y se testea si su coeficiente es cero.
regress cartel2010 chinese_presence $controls i.id_estado, cluster(id_estado)
predict v_hat if e(sample), residuals
regress IM_2015 cartel2010 v_hat $controls i.id_estado, cluster(id_estado)
test v_hat
*     (El comando hausman clásico no es válido con errores clusterizados, por eso
*     no lo usamos.)
