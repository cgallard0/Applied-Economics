/*******************************************************************************
							    Problem Set 6
                              Diff-in-diff

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file:
1) Replica la Tabla 4 de Cheng y Hoekstra (2013). El tratamiento es cdl, la
   proporción del año con la ley vigente.
2) Estima la columna 1 del panel C con el estimador de Callaway y Sant'Anna
   (ATT simple, efectos por grupo, test de pre-tendencias y estudio de eventos).
3) Estima la misma columna con el imputation estimator de Borusyak et al.
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout csdid drdid did_imputation event_plot {
	cap which `pkg'
	if _rc ssc install `pkg'
}

use "$input/castle.dta", clear
xtset sid year

*==============================================================================*

* 1) tabla 4

global region r20001-r20104 // Region by Year Fixed Effects 
global demo blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 // Demographics
global spending l_exp_subsidy l_exp_pubwelfare // Spending
global xvar l_police unemployrt poverty l_income l_prisoner l_lagprisoner $demo $spending // Time-Varying Controls
global crime1 l_larceny l_motor // Contemporaneous Crime Rates (larceny y motor vehicle theft)
global lintrend trend_1-trend_51 // State-Specific Linear Time Trends

label var cdl "Castle Doctrine Law"
label var pre2_cdl "0 to 2 years before adoption"

local all "c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12"
local pan_l_burglary "a"
local pan_l_robbery "b"
local pan_l_assault "c"

foreach y in l_burglary l_robbery l_assault {
	eststo clear
	* columnas 1-6: ponderadas por población; columnas 7-12: sin ponderar
	forvalues w = 0/1 {
		if `w' == 0 local wgt "[aweight=popwt]"
		else local wgt ""
		local o = 6*`w'
		eststo c`=`o'+1': xtreg `y' cdl i.year `wgt', fe cluster(sid)
		eststo c`=`o'+2': xtreg `y' cdl i.year $region `wgt', fe cluster(sid)
		eststo c`=`o'+3': xtreg `y' cdl i.year $region $xvar `wgt', fe cluster(sid)
		eststo c`=`o'+4': xtreg `y' cdl pre2_cdl i.year $region $xvar `wgt', fe cluster(sid)
		eststo c`=`o'+5': xtreg `y' cdl i.year $region $xvar $crime1 `wgt', fe cluster(sid)
		eststo c`=`o'+6': xtreg `y' cdl i.year $region $xvar $lintrend `wgt', fe cluster(sid)
	}
	estadd local sy "Yes" : `all'
	estadd local ry "No" : c1 c7
	estadd local ry "Yes" : c2 c3 c4 c5 c6 c8 c9 c10 c11 c12
	estadd local tvc "No" : c1 c2 c7 c8
	estadd local tvc "Yes" : c3 c4 c5 c6 c9 c10 c11 c12
	estadd local ccr "Yes" : c5 c11
	estadd local ccr "No" : c1 c2 c3 c4 c6 c7 c8 c9 c10 c12
	estadd local ltt "Yes" : c6 c12
	estadd local ltt "No" : c1 c2 c3 c4 c5 c7 c8 c9 c10 c11
	
	esttab `all' using "$output/Tabla 4`pan_`y''.rtf", replace label se b(4) se(4) ///
		keep(cdl pre2_cdl) star(* 0.10 ** 0.05 *** 0.01) nomtitles ///
		stats(N sy ry tvc ccr ltt, fmt(0 0 0 0 0 0) labels("Observations" "State and Year FE" ///
		"Region-by-Year FE" "Time-Varying Controls" "Contemporaneous Crime Rates" "State-Specific Linear Time Trends")) ///
		addnotes("Columns 1-6: OLS weighted by state population. Columns 7-12: unweighted. Robust standard errors clustered at the state level.")
	esttab `all' using "$output/Tabla 4`pan_`y''.tex", replace label booktabs se b(4) se(4) ///
		keep(cdl pre2_cdl) star(* 0.10 ** 0.05 *** 0.01) nomtitles nonotes ///
		stats(N sy ry tvc ccr ltt, fmt(0 0 0 0 0 0) labels("Observaciones" "EF estado y año" ///
		"EF región-año" "Controles" "Delitos contemporáneos" "Tendencias lineales por estado"))
}

*==============================================================================*

* 2) estimador de Callaway y Sant'Anna

* gvar: año de adopción de la ley (primer año con tratamiento); 0 = nunca tratados
gen gvar = effyear
replace gvar = 0 if missing(gvar)

* columna (1) del panel C: sin controles, ponderado por población
* notyet: se usan como controles los estados nunca tratados y los aún no tratados
csdid l_assault [iweight=popwt], ivar(sid) time(year) gvar(gvar) notyet
est store cs

* test de tendencias paralelas (H0: todos los ATT(g,t) pre-tratamiento son 0)
estat pretrend
scalar pre_chi2 = r(chi2)
scalar pre_df = r(df)
scalar pre_p = r(pchi2)

* ATT simple
estat simple
est restore cs
estat simple, post
estadd scalar pre_chi2 = pre_chi2
estadd scalar pre_df = pre_df
estadd scalar pre_p = pre_p
est store cs_simple

* ATT por grupo
est restore cs
estat group

* gráfico para cuatro grupos
est restore cs
csdid_plot, group(2006) name(m1, replace) title("Group 2006")
csdid_plot, group(2007) name(m2, replace) title("Group 2007")
csdid_plot, group(2008) name(m3, replace) title("Group 2008")
csdid_plot, group(2009) name(m4, replace) title("Group 2009")
graph combine m1 m2 m3 m4, xcommon scale(0.8)
graph export "$output/Grafico.png", replace

* estudio de eventos
est restore cs
estat event
csdid_plot, name(ev, replace) title("Event study (Callaway y Sant'Anna)") ///
	xtitle("Años desde la adopción") ytitle("ATT sobre log(aggravated assault)")
graph export "$output/Event_study_CS.png", replace
est restore cs
estat event, post
est store cs_event

esttab cs_simple cs_event using "$output/Callaway_SantAnna.rtf", replace se b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("ATT simple" "Event study") ///
	stats(pre_chi2 pre_df pre_p, fmt(2 0 3) labels("Pretrend test chi2" "df" "p-value"))
esttab cs_simple cs_event using "$output/Callaway_SantAnna.tex", replace booktabs se b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("ATT simple" "Estudio de eventos") nonotes noobs ///
	stats(pre_chi2 pre_df pre_p, fmt(2 0 3) labels("Test pre-tendencias (chi2)" "Grados de libertad" "p-valor"))

*==============================================================================*

* 3) imputation estimator (Borusyak, Jaravel y Spiess)

* Ei: año de adopción; missing para los nunca tratados
gen Ei = effyear

* efecto promedio (sin controles)
did_imputation l_assault sid year Ei [aweight=popwt]
est store bjs

* efectos por horizonte y tendencias previas (5 períodos)
did_imputation l_assault sid year Ei [aweight=popwt], horizons(0/5) pretrends(5) minn(0)
est store bjs_event
cap noisily display "p-valor del test conjunto de pre-trends: " e(pre_p)
event_plot bjs_event, default_look graph_opt(xtitle("Años desde la adopción") ///
	ytitle("Efecto sobre log(aggravated assault)") title("Imputation estimator (BJS)"))
graph export "$output/Event_study_BJS.png", replace

esttab bjs bjs_event using "$output/Imputation.rtf", replace se b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("ATT" "Horizons and pre-trends") ///
	stats(N pre_F pre_p, fmt(0 2 3) labels("Observations" "Pre-trend F" "p-value"))
esttab bjs bjs_event using "$output/Imputation.tex", replace booktabs se b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("ATT" "Horizontes y pre-tendencias") nonotes ///
	stats(N pre_F pre_p, fmt(0 2 3) labels("Observaciones" "F conjunto pre-tendencias" "p-valor"))
