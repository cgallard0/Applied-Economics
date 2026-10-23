/*******************************************************************************
							    Problem Set 8
                            Control sintético

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file replica en Stata las Figuras 1 a 7 de Freire (2018):
1) São Paulo vs. promedio del resto de Brasil.
2) Control sintético y diferencia (gap).
3) Placebo en el tiempo (1995).
4) Leave-one-out.
5) Test de permutación (todos los estados y estados con MSPE bajo).
La sección de placebos estima 27 controles sintéticos y tarda varios minutos.
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"
cd "$output"

* paquetes necesarios
cap which synth
if _rc ssc install synth, all

* especificación (igual a la del código de R): promedios 1990-1998 de PIB per
* cápita, crecimiento del PIB, log de la población, años de escolaridad, tasa de
* homicidios, proporción en extrema pobreza y Gini
global spec "homiciderates stategdpcapita stategdpgrowthpercent populationprojectionln yearsschoolingimp homiciderates(1990(1)1998) pobreza(1990(1)1998) giniimp(1990(1)1998)"

* programa auxiliar para cargar los datos
cap program drop cargar
program define cargar
	import delimited "$input/df.csv", clear
	* synth no acepta nombres largos en los predictores con período (da "invalid name")
	rename proportionextremepoverty pobreza
	tsset code year
end

cargar

*==============================================================================*

* 1) Figura 1

gen homicide_sp = homiciderates if code == 35
gen homicide_other = homiciderates if code != 35

preserve
collapse (mean) homicide_sp homicide_other, by(year)
twoway (line homicide_sp year, lpattern(solid) lcolor(black) lwidth(medium)) ///
       (line homicide_other year, lpattern(shortdash) lcolor(black) lwidth(medium)), ///
       ylabel(0(10)60) xlabel(1990(5)2010, labsize(medium)) ///
       title("") xtitle("Year") ytitle("Homicide Rates") ///
       legend(order(1 "São Paulo" 2 "Brazil (average)") ///
			  position(7) ring(0) col(1)) ///
       xline(1999, lpattern(shortdash) lcolor(black) lwidth(thin)) ///
       text(50 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 1.png", replace
restore

*==============================================================================*

* 2) Synthetic Control - Figuras 2 y 3

synth $spec, trunit(35) trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) nested
matrix W = e(W_weights)
matrix X_bal = e(X_balance)
matrix list W
matrix list X_bal
* pesos y balance de predictores (para el informe)
preserve
clear
svmat W, names(col)
rename (_Co_Number _W_Weight) (code weight)
gsort -weight
list if weight > 0.001, noobs
export delimited using "$output/pesos_sintetico.csv", replace
restore

matrix treated = e(Y_treated)
matrix synthetic = e(Y_synthetic)
matrix gaps = e(Y_treated) - e(Y_synthetic)
preserve
clear
svmat treated
svmat synthetic
svmat gaps
gen year = 1989 + _n

twoway (line treated1 year, lpattern(solid) lcolor(black) lwidth(medium)) ///
       (line synthetic1 year, lpattern(shortdash) lcolor(black) lwidth(medium)), ///
       ylabel(0(10)60) xlabel(1990(5)2010, labsize(medium)) ///
       title("") xtitle("Year") ytitle("Homicide Rates") ///
       legend(order(1 "São Paulo" 2 "Synthetic São Paulo") ///
			  position(7) ring(0) col(1)) ///
       xline(1999, lpattern(shortdash) lcolor(black) lwidth(thin)) ///
       text(50 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 2.png", replace

twoway (line gaps1 year, lpattern(solid) lcolor(black) lwidth(medium)), ///
       ylabel(-30(10)30) xlabel(1990(5)2010, labsize(medium)) ///
       title("") xtitle("Year") ytitle("Gap in Homicide Rates") ///
       xline(1999, lpattern(shortdash) lcolor(black) lwidth(thin)) ///
	   yline(0, lpattern(dash) lcolor(black) lwidth(medium)) ///
       text(20 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 3.png", replace
export delimited year treated1 synthetic1 gaps1 using "$output/sintetico_sp.csv", replace
restore

*==============================================================================*

* 3) Placebo en el tiempo (tratamiento ficticio en 1995) - Figura 4

cargar
synth homiciderates stategdpcapita stategdpgrowthpercent populationprojectionln yearsschoolingimp ///
	homiciderates(1990(1)1994) pobreza(1990(1)1994) giniimp(1990(1)1994), ///
	trunit(35) trperiod(1995) xperiod(1990(1)1994) mspeperiod(1990(1)1994) nested
matrix treated = e(Y_treated)
matrix synthetic = e(Y_synthetic)
preserve
clear
svmat treated
svmat synthetic
gen year = 1989 + _n

twoway (line treated1 year if year <= 1998, lpattern(solid) lcolor(black) lwidth(medium)) ///
       (line synthetic1 year if year <= 1998, lpattern(shortdash) lcolor(black) lwidth(medium)), ///
       ylabel(0(10)50) xlabel(1990(2)1998, labsize(medium)) ///
       title("") xtitle("Year") ytitle("Homicide Rates") ///
       legend(order(1 "São Paulo" 2 "Synthetic São Paulo") ///
			  position(7) ring(0) col(1)) ///
       xline(1995, lpattern(dash) lcolor(black) lwidth(thin)) ///
       text(40 1994 "Placebo Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 4.png", replace
restore

*==============================================================================*

* 4) Leave One Out - Figura 5

cargar
synth $spec, trunit(35) trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) nested ///
	keep(synthetic_results, replace)
use "$output/synthetic_results.dta", clear
ren _Y_synthetic _Y_synthetic_
ren _Y_treated _Y_treated_
save "$output/synthetic_results.dta", replace

* estados que se excluyen (los mismos que en el código de R): RR, RJ, SC y DF
foreach j in 14 33 42 53 {
	cargar
	drop if code == `j'
	* si la optimización nested no converge, se vuelve a estimar sin nested
	cap noisily synth $spec, trunit(35) trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) nested ///
		keep(synthetic_results_`j', replace)
	if _rc synth $spec, trunit(35) trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) ///
		keep(synthetic_results_`j', replace)
	use "$output/synthetic_results_`j'.dta", clear
	keep if !missing(_time)
	ren _Y_synthetic _Y_synthetic_`j'
	keep _time _Y_synthetic_`j'
	save "$output/synthetic_results_`j'.dta", replace
}

use "$output/synthetic_results.dta", clear
keep if !missing(_time)
foreach j in 14 33 42 53 {
    merge 1:1 _time using "$output/synthetic_results_`j'.dta", nogen
}

twoway (line _Y_synthetic_14 _time, lcolor(gs13)) (line _Y_synthetic_33 _time, lcolor(gs13)) ///
	   (line _Y_synthetic_42 _time, lcolor(gs13)) (line _Y_synthetic_53 _time, lcolor(gs13)) ///
	   (line _Y_treated_ _time, lcolor(black)) (line _Y_synthetic_ _time, lpattern(shortdash) lcolor(black)), ///
       ylabel(0(10)60) xlabel(1990(5)2010, labsize(medium)) ///
       title("") xtitle("Year") ytitle("Homicide Rates") ///
	   legend(order(5 "São Paulo" 6 "Synthetic São Paulo" 1 "Synthetic São Paulo (leave-one-out)") ///
			position(7) ring(0) col(1)) ///
       xline(1999, lpattern(dash) lcolor(black) lwidth(thin)) ///
       text(50 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 5.png", replace

*==============================================================================*

* 5) Permutation Test - Figuras 6 y 7

cargar
levelsof code, local(estados)

* se estima un sintético para cada estado. Para los placebos se excluye a São
* Paulo del donor pool (es el único estado tratado).
foreach i of local estados {
	cargar
	if `i' != 35 drop if code == 35
	* si la optimización nested no converge, se vuelve a estimar sin nested
	cap qui synth $spec, trunit(`i') trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) nested ///
		keep(resout`i', replace)
	if _rc qui synth $spec, trunit(`i') trperiod(1999) xperiod(1990(1)1998) mspeperiod(1990(1)1998) ///
		keep(resout`i', replace)
	use "$output/resout`i'.dta", clear
	keep if !missing(_time)
	gen _Y_gap_`i' = _Y_treated - _Y_synthetic
	keep _time _Y_gap_`i'
	save "$output/resout`i'.dta", replace
}

clear
set obs 20
gen _time = 1989 + _n
foreach i of local estados {
	merge 1:1 _time using "$output/resout`i'.dta", nogen
}

* MSPE pre-tratamiento de cada estado y estados con MSPE < 2 veces el de São Paulo
local lines6 ""
foreach i of local estados {
	quietly gen sq_`i' = _Y_gap_`i'^2 if _time < 1999
	quietly summarize sq_`i'
	local mspe_`i' = r(mean)
	drop sq_`i'
	if `i' != 35 local lines6 "`lines6' (line _Y_gap_`i' _time, lcolor(gs13))"
}
local lines7 ""
local low ""
foreach i of local estados {
	if `i' != 35 & `mspe_`i'' < 2*`mspe_35' {
		local lines7 "`lines7' (line _Y_gap_`i' _time, lcolor(gs13))"
		local low "`low' `i'"
	}
}
display "Estados con MSPE pre-tratamiento menor a 2 veces el de São Paulo: `low'"
local n6 : word count `estados'
local n7 : word count `low'
local n7 = `n7' + 1

twoway `lines6' (line _Y_gap_35 _time, lcolor(black) lwidth(medium)), ///
	ylabel(-30(10)30) xlabel(1990(5)2010, labsize(medium)) ///
	title("") xtitle("Year") ytitle("Gap in Homicide Rates") ///
	legend(order(`n6' "São Paulo" 1 "Control States") position(7) ring(0) col(1)) ///
	xline(1999, lpattern(dash) lcolor(black) lwidth(thin)) ///
	yline(0, lcolor(black) lwidth(thin)) ///
	text(25 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 6.png", replace

twoway `lines7' (line _Y_gap_35 _time, lcolor(black) lwidth(medium)), ///
	ylabel(-30(10)30) xlabel(1990(5)2010, labsize(medium)) ///
	title("") xtitle("Year") ytitle("Gap in Homicide Rates") ///
	legend(order(`n7' "São Paulo" 1 "Control States (MSPE Less Than Two Times That of São Paulo)") ///
		position(7) ring(0) col(1)) ///
	xline(1999, lpattern(dash) lcolor(black) lwidth(thin)) ///
	yline(0, lcolor(black) lwidth(thin)) ///
	text(25 1994 "Policy Change", place(w) color(black) size(small))
graph export "$output/Figura 7.png", replace
