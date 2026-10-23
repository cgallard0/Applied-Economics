/*******************************************************************************
							    Problem Set 11
                                Matching

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file:
1) Hace tests de medias entre distritos tratados y no tratados.
2) Estima el propensity score y define el soporte común.
3) Realiza el matching (vecino más cercano sin reemplazo).
4) Repite los tests de medias en la muestra matcheada.
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"
cd "$output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout psmatch2 {
	cap which `pkg'
	if _rc ssc install `pkg'
}

use "$input/base_censo.dta", clear

*==============================================================================*

* 1) test de medias

label var pobl_1999 "Población 1999"
label var via1 "Principal vía de acceso: carretera asfaltada"
label var ranking_pobr "Ranking de pobreza"

estpost ttest pobl_1999, by(treated)
esttab using "$output/Tabla 1.rtf", replace label

estpost ttest via1, by(treated)
esttab using "$output/Tabla 2.rtf", replace label

estpost ttest ranking_pobr, by(treated)
esttab using "$output/Tabla 3.rtf", replace label

* las tres variables juntas (diferencia = no tratados - tratados)
estpost ttest pobl_1999 via1 ranking_pobr, by(treated)
est store antes

*==============================================================================*

* 2) propensity score

global X ind_abs_pobr ldens_pob prov_cap pob_1 pob_2 pob_3 pob_4 km_cap_prov via3 via5 via7 via9 region_2 region_3 laltitud tdesnutr deficit_post deficit_aulas

foreach var of varlist $X { 
	drop if `var'==.
}

probit treated $X
est store probit
esttab probit using "$output/Tabla 7.tex", replace booktabs b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes mtitles("Treated (probit)") eqlabels(none) ///
	stats(N r2_p, fmt(%9.0fc 3) labels("Observaciones" "Pseudo R2"))
predict p_score

*==============================================================================*

* 3) grafico propensity score

twoway  (kdensity p_score if treated==1,lwidth(thick) lpattern(solid) lcolor(magenta)) ///
		(kdensity p_score if treated==0, lwidth(thick) lpattern(solid) lcolor(blue)), ///
		scheme(s1mono) legend(lab(1 "Treated") lab(2 "Not treated")) ///
		xtitle("Propensity Score") ytitle("Density")
graph export "$output/Figura 1.png", replace

*==============================================================================*

* 4) variable binaria common support

bysort treated: summ p_score
egen x = min(p_score) if treated == 1
egen psmin = min(x)
egen y = max(p_score) if treated == 0
egen psmax = max(y)
drop x y

gen cs1 = 1 if (p_score >= psmin & p_score <= psmax) & p_score != .
replace cs1 = 0 if cs1 == .
tab treated cs1

* nos quedamos solo con las observaciones dentro del soporte común
keep if cs1 == 1

*==============================================================================*

* 5) matching (vecino más cercano sin reemplazo)
* Nota: con noreplacement el resultado depende del orden de los datos.

psmatch2 treated if cs1 == 1, p(p_score) noreplacement
gen matches = _weight
replace matches = 0 if matches == .

* balance de las variables del propensity score antes y después del matching
pstest $X, both

*==============================================================================*

* 6) distribucion propensity score con matches == 1

twoway  (kdensity p_score if (treated==1 & matches == 1),lwidth(thick) lpattern(solid) lcolor(magenta)) ///
		(kdensity p_score if (treated==0 & matches == 1), lwidth(thick) lpattern(dash) lcolor(blue)), ///
		scheme(s1mono) legend(lab(1 "Treated") lab(2 "Not treated")) ///
		xtitle("Propensity Score") ytitle("Density")
graph export "$output/Figura 2.png", replace

*==============================================================================*

* 7) test de medias con matches == 1

estpost ttest pobl_1999 if matches == 1, by(treated)
esttab using "$output/Tabla 4.rtf", replace label

estpost ttest via1 if matches == 1, by(treated)
esttab using "$output/Tabla 5.rtf", replace label

estpost ttest ranking_pobr if matches == 1, by(treated)
esttab using "$output/Tabla 6.rtf", replace label

estpost ttest pobl_1999 via1 ranking_pobr if matches == 1, by(treated)
est store despues

* tabla LaTeX con los tests de medias antes y después del matching
esttab antes despues using "$output/Tabla 1.tex", replace booktabs label ///
	cells("b(fmt(2) star) t(fmt(2))") collabels("Diferencia" "t") ///
	mtitles("Muestra completa" "Muestra matcheada") nonumber noobs nonotes
