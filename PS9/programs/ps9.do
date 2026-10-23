/*******************************************************************************
							    Problem Set 9

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"
cd "$output"

* Nota: rnormal(m, s) toma como segundo argumento el DESVÍO estándar. Siguiendo
* la tutorial, "varianza del error = 500" corresponde a rnormal(0,500) y
* "varianza = 5000" a rnormal(0,5000). Además, como en la tutorial, se eliminan
* las observaciones con impuestos negativos; con desvío 5000 esto descarta
* alrededor de un tercio de la población simulada.

*==============================================================================*

* 1) Grafico

set matsize 600
set seed 123
set obs 15000
gen ganancias_estimadas = rnormal(10000,2000)
drop if ganancias_estimadas<0
gen impuestos_pagados = 0.2*ganancias_estimadas + rnormal(0,500)
drop if impuestos_pagados<0
gen obs=_n
pctile escuela = obs, nq(10)

local i=1
mat resultados = J(50,4,.)

foreach efecto in 0.01 0.025 0.05 0.075 0.1{
	forvalues size = 1000(1000)10000 {
		mat R = J(500,2,.) 

			forvalues x=1(1)500 {
				preserve
				sample `size' , count
				gen temp = runiform()
				gen T=0
				replace T = 1 if temp<0.5
				replace impuestos_pagados = impuestos_pagados * (1+`efecto') if T==1
				reg impuestos_pagados T, robust
				mat R[`x',1]=_b[T]/_se[T]
				restore
			}

	preserve
	clear
	svmat R
	gen reject = 0
	replace reject = 1 if (R1>1.65)
	drop if reject==.
	sum reject
	scalar media = r(mean)

	mat resultados[`i',3] = `efecto'
	mat resultados[`i',2] = media
	mat resultados[`i',1] = `size'
	restore

	local i=`i'+1
	}
}

clear 
svmat resultados
rename resultados1 sample_size
rename resultados2 st_power
rename resultados3 efecto
replace st_power=round(st_power,.01)
separate st_power, by(efecto)

twoway (connected st_power1 sample_size) (connected st_power2 sample_size) ///
(connected st_power3 sample_size) (connected st_power4 sample_size) ///
(connected st_power5 sample_size), ytitle("Power") ///
xtitle("Number of observations") ///
legend(label(1 "1%") label(2 "2.5%") label(3 "5%") label(4 "7.5%") label(5 "10%")) ///
legend(rows(1) title("Effect", size(small)) pos(6) ring(1)) xscale(titlegap(3)) yscale(titlegap(3)) 
graph export "$output/Figura 1.png", replace

*==============================================================================*

* 2) Simulacion: distinta varianza

clear all
set seed 123 
set obs 15000
gen ganancias_estimadas = rnormal(10000,2000)
drop if ganancias_estimadas<0
gen impuestos_pagados = 0.2*ganancias_estimadas + rnormal(0,5000) // cambiamos la varianza del error a 5000
drop if impuestos_pagados<0
gen obs=_n
pctile escuela = obs, nq(10)

local i=1
mat resultados = J(50,4,.)
foreach efecto in 0.01 0.025 0.05 0.075 0.1{
	forvalues size = 1000(1000)10000 {
		mat R = J(500,2,.) 

			forvalues x=1(1)500 {
				preserve
				sample `size' , count
				gen temp = runiform()
				gen T=0
				replace T = 1 if temp<0.5
				replace impuestos_pagados = impuestos_pagados * (1+`efecto') if T==1
				reg impuestos_pagados T, robust
				mat R[`x',1]=_b[T]/_se[T]
				restore
			}

	preserve
	clear
	svmat R
	gen reject = 0
	replace reject = 1 if (R1>1.65)
	drop if reject==.
	sum reject
	scalar media = r(mean)

	mat resultados[`i',3] = `efecto'
	mat resultados[`i',2] = media
	mat resultados[`i',1] = `size'
	restore

	local i=`i'+1
	}
}

clear 
svmat resultados
rename resultados1 sample_size
rename resultados2 st_power
rename resultados3 efecto
replace st_power=round(st_power,.01)
separate st_power, by(efecto)

twoway (connected st_power1 sample_size) (connected st_power2 sample_size) ///
(connected st_power3 sample_size) (connected st_power4 sample_size) ///
(connected st_power5 sample_size), ytitle("Power") ///
xtitle("Number of observations") ///
legend(label(1 "1%") label(2 "2.5%") label(3 "5%") label(4 "7.5%") label(5 "10%")) ///
legend(rows(1) title("Effect", size(small)) pos(6) ring(1)) xscale(titlegap(3)) yscale(titlegap(3)) 
graph export "$output/Figura 2.png", replace

*==============================================================================*

* 3) Simulaciones: distinto porcentaje tratados

*20% de tratados
clear all
set seed 123 
set obs 15000
gen ganancias_estimadas = rnormal(10000,2000)
drop if ganancias_estimadas<0
gen impuestos_pagados = 0.2*ganancias_estimadas + rnormal(0,5000) // cambiamos la varianza del error a 5000
drop if impuestos_pagados<0
gen obs=_n
pctile escuela = obs, nq(10)

local i=1
mat resultados = J(50,4,.)
foreach efecto in 0.01 0.025 0.05 0.075 0.1{
	forvalues size = 1000(1000)10000 {
		mat R = J(500,2,.) 

			forvalues x=1(1)500 {
				preserve
				sample `size' , count
				gen temp = runiform()
				gen T=0
				replace T = 1 if temp<0.2
				replace impuestos_pagados = impuestos_pagados * (1+`efecto') if T==1
				reg impuestos_pagados T, robust
				mat R[`x',1]=_b[T]/_se[T]
				restore
			}

	preserve
	clear
	svmat R
	gen reject = 0
	replace reject = 1 if (R1>1.65)
	drop if reject==.
	sum reject
	scalar media = r(mean)

	mat resultados[`i',3] = `efecto'
	mat resultados[`i',2] = media
	mat resultados[`i',1] = `size'
	restore

	local i=`i'+1
	}
}

clear 
svmat resultados
rename resultados1 sample_size
rename resultados2 st_power
rename resultados3 efecto
replace st_power=round(st_power,.01)
separate st_power, by(efecto)

twoway (connected st_power1 sample_size) (connected st_power2 sample_size) ///
(connected st_power3 sample_size) (connected st_power4 sample_size) ///
(connected st_power5 sample_size), ytitle("Power") ///
xtitle("Number of observations") ///
legend(label(1 "1%") label(2 "2.5%") label(3 "5%") label(4 "7.5%") label(5 "10%")) ///
legend(rows(1) title("Effect", size(small)) pos(6) ring(1)) xscale(titlegap(3)) yscale(titlegap(3)) 
graph export "$output/Figura 3.png", replace

*80% de tratados
clear all
set seed 123 
set obs 15000
gen ganancias_estimadas = rnormal(10000,2000)
drop if ganancias_estimadas<0
gen impuestos_pagados = 0.2*ganancias_estimadas + rnormal(0,5000) // cambiamos la varianza del error a 5000
drop if impuestos_pagados<0
gen obs=_n
pctile escuela = obs, nq(10)

local i=1
mat resultados = J(50,4,.)
foreach efecto in 0.01 0.025 0.05 0.075 0.1{
	forvalues size = 1000(1000)10000 {
		mat R = J(500,2,.) 

			forvalues x=1(1)500 {
				preserve
				sample `size' , count
				gen temp = runiform()
				gen T=0
				replace T = 1 if temp<0.8
				replace impuestos_pagados = impuestos_pagados * (1+`efecto') if T==1
				reg impuestos_pagados T, robust
				mat R[`x',1]=_b[T]/_se[T]
				restore
			}

	preserve
	clear
	svmat R
	gen reject = 0
	replace reject = 1 if (R1>1.65)
	drop if reject==.
	sum reject
	scalar media = r(mean)

	mat resultados[`i',3] = `efecto'
	mat resultados[`i',2] = media
	mat resultados[`i',1] = `size'
	restore

	local i=`i'+1
	}
}

clear 
svmat resultados
rename resultados1 sample_size
rename resultados2 st_power
rename resultados3 efecto
replace st_power=round(st_power,.01)
separate st_power, by(efecto)

twoway (connected st_power1 sample_size) (connected st_power2 sample_size) ///
(connected st_power3 sample_size) (connected st_power4 sample_size) ///
(connected st_power5 sample_size), ytitle("Power") ///
xtitle("Number of observations") ///
legend(label(1 "1%") label(2 "2.5%") label(3 "5%") label(4 "7.5%") label(5 "10%")) ///
legend(rows(1) title("Effect", size(small)) pos(6) ring(1)) xscale(titlegap(3)) yscale(titlegap(3)) 
graph export "$output/Figura 4.png", replace

*==============================================================================*

* 4) Simulacion: control

clear all
set more off
set seed 123 
set obs 15000
gen ganancias_estimadas = rnormal(10000,2000)
drop if ganancias_estimadas<0
gen impuestos_pagados = 0.2*ganancias_estimadas + rnormal(0,500) // cambiamos la varianza del error a 500
drop if impuestos_pagados<0
gen obs=_n
pctile escuela = obs, nq(10)

local i=1
mat resultados = J(50,4,.)
foreach efecto in 0.01 0.025 0.05 0.075 0.1{
	forvalues size = 1000(1000)10000 {
		mat R = J(500,2,.) 

			forvalues x=1(1)500 {
				preserve
				sample `size' , count
				gen temp = runiform()
				gen T=0
				replace T = 1 if temp<0.5
				replace impuestos_pagados = impuestos_pagados * (1+`efecto') if T==1
				reg impuestos_pagados T ganancias_estimadas, robust
				mat R[`x',1]=_b[T]/_se[T]
				restore
			}

	preserve
	clear
	svmat R
	gen reject = 0
	replace reject = 1 if (R1>1.65)
	drop if reject==.
	sum reject
	scalar media = r(mean)

	mat resultados[`i',3] = `efecto'
	mat resultados[`i',2] = media
	mat resultados[`i',1] = `size'
	restore

	local i=`i'+1
	}
}

clear 
svmat resultados
rename resultados1 sample_size
rename resultados2 st_power
rename resultados3 efecto
replace st_power=round(st_power,.01)
separate st_power, by(efecto)

twoway (connected st_power1 sample_size) (connected st_power2 sample_size) ///
(connected st_power3 sample_size) (connected st_power4 sample_size) ///
(connected st_power5 sample_size), ytitle("Power") ///
xtitle("Number of observations") ///
legend(label(1 "1%") label(2 "2.5%") label(3 "5%") label(4 "7.5%") label(5 "10%")) ///
legend(rows(1) title("Effect", size(small)) pos(6) ring(1)) xscale(titlegap(3)) yscale(titlegap(3)) 
graph export "$output/Figura 5.png", replace
