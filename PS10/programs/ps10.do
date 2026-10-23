/*******************************************************************************
							    Problem Set 10
                        Regression discontinuity

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file:
A-B) Estima regresiones MCO del tamaño de la clase sobre las notas.
D) Realiza las pruebas de validez del RD (densidad a nivel escuela y continuidad
   de la covariable).
E-F) Estima el RD fuzzy (umbral en 40.5) con polinomios de grado 1 a 4 y con
   bandwidths de 7, 10 y 15.
G) Estima por IV con la regla de Maimónides.
Los datos son a nivel de clase. Como no hay identificador de escuela, la escuela
se aproxima con las combinaciones únicas de enroll y tip_a (tip_a es una
variable de la escuela).
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"
cd "$output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout {
	cap which `pkg'
	if _rc ssc install `pkg'
}
cap which rdrobust
if _rc net install rdrobust, from("https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata") replace
cap which rddensity
if _rc net install rddensity, from("https://raw.githubusercontent.com/rdpackages/rddensity/master/stata") replace
cap which lpdensity
if _rc net install lpdensity, from("https://raw.githubusercontent.com/nppackages/lpdensity/master/stata") replace

use "$input/grades5.dta", clear

* identificador aproximado de escuela (tip_a es una variable a nivel escuela)
egen school = group(enroll tip_a), missing

label var classize "Class size"
label var tip_a "Percent disadvantaged"
label var enroll "Enrollment"

*==============================================================================*

* A) Regresiones simples (errores clusterizados por escuela)

eststo clear
eststo a1: reg avgmath classize, vce(cluster school)
eststo a2: reg avgverb classize, vce(cluster school)

*==============================================================================*

* B) Regresiones con controles

eststo b1: reg avgmath classize tip_a enroll, vce(cluster school)
eststo b2: reg avgverb classize tip_a enroll, vce(cluster school)

esttab a1 a2 b1 b2 using "$output/Tabla 1.tex", replace label booktabs b(4) se(4) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("Math" "Verbal" "Math" "Verbal") ///
	r2 nonotes stats(N r2, fmt(%9.0fc 3) labels("Observaciones" "R-cuadrado"))

*==============================================================================*

* D) Pruebas de validez del RDD

global y1 avgmath
global y2 avgverb
global x enroll
global c 40.5
global covs tip_a

* (1) test de densidad (McCrary / Cattaneo, Jansson y Ma)
* a nivel de clase la densidad salta mecánicamente (las escuelas con más de 40
* inscriptos aportan dos clases), así que el test relevante es a nivel de escuela
rddensity $x, c($c)
preserve
duplicates drop school, force
rddensity $x, c($c) plot graph_opt(xtitle("Enrollment") ytitle("Densidad") legend(off))
graph export "$output/RD_densidad.png", replace
restore

* (2) placebo: continuidad de la covariable predeterminada en el umbral
rdrobust $covs $x, c($c) vce(nncluster school)
rdplot $covs $x, c($c) p(1) graph_options(graphregion(color(white)) ///
	xtitle("Enrollment") ytitle("Porcentaje de estudiantes desfavorecidos") legend(off))
graph export "$output/RD_covariable.png", replace

* (3) primera etapa: salto en el tamaño de la clase
rdrobust classize $x, c($c) vce(nncluster school)
rdplot classize $x, c($c) p(1) graph_options(graphregion(color(white)) ///
	xtitle("Enrollment") ytitle("Class size") legend(off))
graph export "$output/RD_primera_etapa.png", replace

*==============================================================================*

* E) Regression discontinuity (continuity-based approach), polinomios de grado 1 a 4

eststo clear
local k = 0
foreach v in 1 2 {
	if `v' == 1 local tit "Promedio en Matemática"
	else local tit "Promedio en Lengua"
	foreach p in 1 2 3 4 {
		local ++k
		* RD fuzzy: efecto de un alumno más por clase
		eststo f`k': rdrobust ${y`v'} $x, c($c) p(`p') fuzzy(classize) covs($covs) vce(nncluster school)
		* gráfico de la forma reducida
		rdplot ${y`v'} $x, c($c) p(`p') graph_options(graphregion(color(white)) ///
			xtitle("Enrollment") ytitle("`tit'") title("Polinomio de grado `p'") ///
			legend(off) name(g`v'_`p', replace))
	}
	graph combine g`v'_1 g`v'_2 g`v'_3 g`v'_4, xcommon scale(0.6)
	graph export "$output/RD_y`v'_polinomios.png", replace
}

esttab f1 f2 f3 f4 f5 f6 f7 f8 using "$output/Tabla 2.tex", replace booktabs b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes coeflabels(RD_Estimate "Class size (RD fuzzy)") ///
	mtitles("Math p=1" "Math p=2" "Math p=3" "Math p=4" "Verbal p=1" "Verbal p=2" "Verbal p=3" "Verbal p=4") ///
	stats(pv_rb h_l N_h_l N_h_r, fmt(3 2 0 0) labels("p-valor robusto" "Bandwidth" "N izquierda" "N derecha"))

*==============================================================================*

* F) RD con bandwidth 7, 10 y 15 (polinomio de grado 1)

eststo clear
local k = 0
foreach v in 1 2 {
	if `v' == 1 local tit "Promedio en Matemática"
	else local tit "Promedio en Lengua"
	foreach h in 7 10 15 {
		local ++k
		eststo h`k': rdrobust ${y`v'} $x, c($c) p(1) h(`h') fuzzy(classize) covs($covs) vce(nncluster school)
		rdplot ${y`v'} $x, c($c) p(1) h(`h') graph_options(graphregion(color(white)) ///
			xtitle("Enrollment") ytitle("`tit'") title("Bandwidth = `h'") legend(off))
		graph export "$output/RD_y`v'_h`h'.png", replace
	}
}

esttab h1 h2 h3 h4 h5 h6 using "$output/Tabla 3.tex", replace booktabs b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes coeflabels(RD_Estimate "Class size (RD fuzzy)") ///
	mtitles("Math h=7" "Math h=10" "Math h=15" "Verbal h=7" "Verbal h=10" "Verbal h=15") ///
	stats(pv_rb h_l N_h_l N_h_r, fmt(3 2 0 0) labels("p-valor robusto" "Bandwidth" "N izquierda" "N derecha"))

*==============================================================================*

* G) Regla de Maimónides como instrumento

gen z = enroll / (floor((enroll - 1) / 40) + 1)
label var z "Maimonides rule"

eststo clear
eststo iv1: ivregress 2sls $y1 tip_a (classize = z), vce(cluster school)
eststo iv2: ivregress 2sls $y1 tip_a enroll (classize = z), vce(cluster school)
eststo iv3: ivregress 2sls $y2 tip_a (classize = z), vce(cluster school)
eststo iv4: ivregress 2sls $y2 tip_a enroll (classize = z), vce(cluster school)

esttab iv1 iv2 iv3 iv4 using "$output/Tabla 4.tex", replace label booktabs b(4) se(4) ///
	star(* 0.10 ** 0.05 *** 0.01) mtitles("Math" "Math" "Verbal" "Verbal") nonotes ///
	stats(N, fmt(%9.0fc) labels("Observaciones"))
