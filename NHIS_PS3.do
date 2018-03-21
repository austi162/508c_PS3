************* WWS508c PS3 *************
*  Spring 2018			              *
*  Author : Chris Austin              *
*  Email: chris.austin@princeton.edu  *
***************************************

/* Credit: Somya Bajaj, Joelle Gamble, Anastasia Korolkova, Luke Strathmann, Chris Austin
Last modified by: Chris Austin
Last modified on: 3/21/18 */

clear all

*Set directory, dta file, etc.
*cd "C:\Users\TerryMoon\Dropbox\Teac=hing Princeton\wws508c 2018S\ps\ps2"
cd "C:\Users\Chris\Documents\Princeton\WWS Spring 2018\WWS 508c\PS3\DTA"
use nhis2000

set more off
set matsize 10000
capture log close
pause on
log using PS2.log, replace

*Download outreg2
ssc install outreg2

********************************************************************************
**                                   P1                                       **
********************************************************************************
//Generate a binary variable that equals one if the respondent reports fair or 
//poor health. 
gen badhealth = health == 4 | health == 5
replace badhealth = . if health == .

//Summarize the data
su age sex marstat white black hisp other health badhealth

foreach var in white black hisp other {
	tab badhealth `var', co
	tab mort5 `var', co
	}
  
label variable badhealth "Poor or fair health"
label define healthunit 1 "Poor or fair health" 0 "Good, very good or excellent health"
label value badhealth healthunit

*most people are healthy, white, female, and around age 50.

pause

********************************************************************************
**                                   P2                                       **
********************************************************************************
//To get a basic sense of how mortality and self-reported health status evolve 
//with age, show line graphs of rates of mortality and fair/poor health by age, 
//with one line for men and one line for women. Are the patterns as you expected? 
//Describe any notable differences between the graphs.

graph twoway lfit mort5 age if sex == 1 || ///
lfit mort5 age if sex == 2, legend(label(1 "Male") label(2 "Female")) ytitle(Died within 5 years of the survey)

graph twoway lfit badhealth age if sex == 1 || ///
lfit badhealth age if sex == 2, legend(label(1 "Male") label(2 "Female")) ytitle(Self-identified as poor or fair health)

pause

********************************************************************************
**                                   P3                                       **
********************************************************************************
// Now use bar graphs to describe the relationship between socioeconomic 
// variables and health. (You need not disaggregate by sex, but you may if you
// so desire.)

//First, graph rates of mortality and fair/poor health by the level of family income

*create last income bin
gen faminc_lt20 = faminc_20t75 == 0 & faminc_gt75 == 0
replace faminc_lt20 = . if faminc_20t75 == . & faminc_gt75 == .

*Create income categorical variable
gen faminc_cat = faminc_lt20 == 1
replace faminc_cat = 2 if faminc_20t75 == 1
replace faminc_cat = 3 if faminc_gt75 == 1
replace faminc_cat = . if faminc_lt20 == . & faminc_20t75 == . & faminc_gt75 == .

label variable faminc_lt20 "Family income < 20k"
label define inclevels 1 "Family income < 25k" 2 "Family income 20-75k" 3 "Family income > 75k" 
label value faminc_cat inclevels
label variable faminc_cat "Family income levels"

*Graph differences by income category
graph bar badhealth mort5, by(faminc_cat) legend(label(1 "Poor or fair health") label(2 "Died within 5 years of survey"))

//Second, graph rates of mortality and fair/poor health by education level, with 
//five categories of educational attainment: less than high school completion (<12),
//high school completion (12), some college (13-15), college completion (16), 
//and post-graduate study (>16).

*Create education category variable	
recode edyrs (1/11=1) (12=2) (13/15=3) (16=4) (17/19=5), gen(edyrs_cat)
	
label variable edyrs_cat "Education level"
label define edlevels 1 "Less than HS completion" 2 "HS completion" 3 "Some college" 4 "College completion" 5 "Post-graduate study"
label value edyrs_cat edlevels

*Graph badhealth and mort5 by education categories
graph bar badhealth mort5, by(edyrs_cat) legend(label(1 "Poor or fair health") label(2 "Died within 5 years of survey"))

//Third, graph rates of mortality and fair/poor health by race/ethnicity. Focus 
//only on non-Hispanic whites, non-Hispanic blacks, and Hispanics.

*Create race category varible
gen race_cat = black
replace race_cat = 1 if black == 1
replace race_cat = 2 if hisp == 1
replace race_cat = 3 if white == 1
replace race_cat = . if black == . & hisp == . & white == .
replace race_cat = . if black == 0 & hisp == 0 & white == 0

label variable race_cat race
label define race 1 "Black" 2 "Hispanic" 3 "White" 0 "Other"
label value race_cat race

*Graph badhealth and mort5 by race categories.
graph bar badhealth mort5, by(race_cat) legend(label(1 "Poor or fair health") label(2 "Died within 5 years of survey"))

pause

********************************************************************************
**                                   P4                                       **
********************************************************************************
//Age, income, education, and race/ethnicity are correlated, so we must use 
//multiple regression to disentangle the relative importance of these variables 
//in determining health. 

//For both 5-year mortality and fair/poor health, run linear probability models, 
//probit models, and logit models with age, education, family income, and 
//race/ethnicity as independent variables. Choose an appropriate functional form
//for age and education (linear, categorical, etc.), and be sure to motivate your 
//choice in your write-up.(Remember that complicated functional forms are 
//sometimes difficult to interpret, and interpretability is valuable.) 

*I'm choosing to bin education to make output more interpretable. This is because
*passing some education threshholds are more important than others and is most
*likely not linear. Age, on the other hand, may be more linear and will be left
*as a continuous variable.

local controls age edyrs_cat faminc_cat race_cat

reg mort5 age edyrs_cat faminc_cat race_cat, r
predict p_ols

probit mort5 age edyrs_cat faminc_cat race_cat, r
predict p_probit

logit mort5 age edyrs_cat faminc_cat race_cat, r
predict p_logit

sum p_*
corr p_*

reg badhealth age edyrs_cat faminc_cat race_cat, r
predict b_ols

probit badhealth age edyrs_cat faminc_cat race_cat, r
predict b_probit

logit badhealth age edyrs_cat faminc_cat race_cat, r
predict b_logit

sum b_*
corr b_*

//For the probit and logit models, compute the marginal effects of the 
//independent variables. Describe your results and take note of any expected or
//unexpected patterns. Are the LP, probit, and logit results similar?

probit mort5 age edyrs_cat faminc_lt20 faminc_20t75 white hisp other, r
mfx compute

pause

logit mort5 age edyrs_cat faminc_lt20 faminc_20t75 white hisp other, r
mfx compute

pause

probit badhealth age edyrs_cat faminc_lt20 faminc_20t75 white hisp other, r
mfx compute 

pause

logit mort5 age edyrs_cat faminc_lt20 faminc_20t75 white hisp other, r
mfx compute

pause

********************************************************************************
**                                   P5                                       **
********************************************************************************
//Holding all else equal, do high-income African-Americans have higher or lower 
//mortality risk than low incomewhites? Use your estimates from one of the models 
//in question (4) to run this test. 
preserve

foreach var in age edyrs_cat faminc_cat race_cat {
	su `var'
	gen `var'_mean = r(mean)
}

probit mort5 age edyrs_cat faminc_cat race_cat, r

*For average person
di normprob(_b[age]*age_mean + _b[edyrs_cat]*edyrs_cat_mean + _b[faminc_cat]*faminc_cat_mean +_b[race_cat]*race_cat_mean + _b[_cons])

*Relative risk for high-income African-Americans = 2.6%
di normprob(_b[age]*age_mean + _b[edyrs_cat]*edyrs_cat_mean + _b[faminc_cat]*3 +_b[race_cat]*1 + _b[_cons])

*Relative risk for low-income whites = 5.1% / nearly 2x more likely than high-income blacks
di normprob(_b[age]*age_mean + _b[edyrs_cat]*edyrs_cat_mean + _b[faminc_cat]*1 +_b[race_cat]*3 + _b[_cons])

restore

//Do you think this regression specification is appropriate for testing for 
//differences between high-income African-Americans and low-income whites? If 
//not, how would you alter it?

*?

pause

********************************************************************************
**                                   P6                                       **
********************************************************************************
//Should we think of the coefficients (or marginal effects) on family income as
//causal? Why or why not?

*No?

********************************************************************************
**                                   P7                                       **
********************************************************************************
//Many wonder how much of the relationship between socioeconomic status and 
//health reflects differences in health insurance or differences in health 
//behaviors. Using one of the above models (LP, probit, or logit), explore the 
//role of these mediating variables. Make sure you are able to interpret the 
//coefficients of the technique you use.

local socioeconomic_controls edyrs race_cat

*Step 1. Check correlation between income bins and health behaviors to determine if we're encountering OVB
corr faminc_lt20 bmi uninsured cancerev cheartdiev heartattev hypertenev diabeticev alc5upyr smokev vig10fwk bacon

corr faminc_20t75 bmi uninsured cancerev cheartdiev heartattev hypertenev diabeticev alc5upyr smokev vig10fwk bacon

corr faminc_gt75 bmi uninsured cancerev cheartdiev heartattev hypertenev diabeticev alc5upyr smokev vig10fwk bacon 

*Step 2. Check significance of IV on DV without mediating variable. Testing whether Uninsured is mediator. 
logistic badhealth faminc_lt20 faminc_20t75 `socioeconomic_controls'
logistic mort5 faminc_lt20 faminc_20t75 `socioeconomic_controls'

*Step 3. Check significance of IV and Mediator after including Mediator in reg
logistic badhealth faminc_lt20 faminc_20t75 uninsured `socioeconomic_controls'
logistic mort5 faminc_lt20 faminc_20t75 uninsured `socioeconomic_controls'

*Step 4. Compare indirect and direct mediation levels
** uninsured had the highest degree of correlation and therefore the greatest
** liklihood of acting as a mediating variable. Yet adding uninsured only
**increased the odds of poor folks being diagnosed with "poor or fair" health 
**9.3x to 10.3x. Similarly, adding uninsured increased the odds of poorer folks 
**from dying within 5 years of the survey from 6.2x to 7.8x.

pause 
********************************************************************************
**                                   P8                                       **
********************************************************************************
//When we recategorized health status as a binary variable, we may have thrown 
//out useful information. Does the five category version of self-reported health
//status predict mortality? Is the relationship monotonic, or does mortality rise
//only after self-reported health becomes fair or poor?

preserve

oprobit mort5 health faminc_cat edyrs race_cat uninsured

*Generate predictions by self-reported health status, setting all the other
*covariates equal to their means:
foreach var in faminc_cat edyrs race_cat uninsured {
  sum `var'
  replace `var' = r(mean)	
  }

*we generate predicted probability, for mort5 = 1
predict p_hat_0, outcome(0)
predict p_hat_1, outcome(1)

*graph the results
sort health
twoway (connect p_hat_1 health), ///
       legend(label(1 "Died within 5 yrs")) ytitle(Predicted probability) title(Predicted probability of dying within 5 years)

restore

*The sicker you identify, the more likely you would die within 5 years of the survey.
*The relationship increases exponentially, so the "fair or poor" grouping increases
*at a higher rate than "excellent to good" grouping.

pause

********************************************************************************
**                                   P9                                       **
********************************************************************************
//Use an ordered probit to estimate the full relationship between socioeconomic
//variables and health status, as in question (4). Are the results similar to 
//the results based on the binary health status variable? Which set of results 
//in question (4) provides coefficients on a comparable scale?

oprobit health faminc_lt20 faminc_20t75 edyrs black hisp other
mfx compute 

probit badhealth faminc_lt20 faminc_20t75 edyrs black hisp other 
mfx compute

*binary probit overestimated the liklihood 

pause

********************************************************************************
**                                   P10                                       **
********************************************************************************
//Use your estimates from question (9) to generate predicted probabilities of
//being in each health status categories. Plot the distribution of predicted 
//probabilities for whites and for blacks. How do these distributions differ? 

**Graph for black == 1
oprobit health faminc_cat edyrs uninsured if black == 1

*Generate predictions by self-reported health status, setting all the other
*covariates equal to their means:
foreach var in edyrs uninsured {
  sum `var'
  replace `var' = r(mean)
  }

*Generate predicted probability, by health status
predict b_hat_1, outcome(1)
predict b_hat_2, outcome(2)
predict b_hat_3, outcome(3)
predict b_hat_4, outcome(4)
predict b_hat_5, outcome(5)

*graph the results
sort faminc_cat
twoway (connect b_hat_1 faminc_cat)(connect b_hat_2 faminc_cat)(connect b_hat_3 faminc_cat)(connect b_hat_4 faminc_cat)(connect b_hat_5 faminc_cat), ///
	legend(label(1 "Excellent") label(2 "Very good") label(3 "Good") label(4 "Fair") label(5 "Poor")) ///
	ytitle(Predicted probability) title(Predicted probability of health status) subtitle(black == 1)

**run again for white == 1
oprobit health faminc_cat edyrs uninsured if white == 1

*Generate predictions by self-reported health status, setting all the other
*covariates equal to their means:
foreach var in edyrs uninsured {
  sum `var'
  replace `var' = r(mean)
  }

*Generate predicted probability, by health status
predict w_hat_1, outcome(1)
predict w_hat_2, outcome(2)
predict w_hat_3, outcome(3)
predict w_hat_4, outcome(4)
predict w_hat_5, outcome(5)

*graph the results
twoway (connect w_hat_1 faminc_cat)(connect w_hat_2 faminc_cat)(connect w_hat_3 faminc_cat)(connect w_hat_4 faminc_cat)(connect w_hat_5 faminc_cat), ///
       legend(label(1 "Excellent") label(2 "Very good") label(3 "Good") label(4 "Fair") label(5 "Poor")) ///
	   ytitle(Predicted probability) title(Predicted probability of health status) subtitle(white == 1)

*generate differences in predicted probability between races, by health status
forv i = 1/5 {
	gen diff_hat_`i' = w_hat_`i' - b_hat_`i'  
	}
	   
//How do they compare with the unadjusted histogram of self-reported health 
//status for blacks and whites?
twoway (connect diff_hat_1 faminc_cat)(connect diff_hat_2 faminc_cat)(connect diff_hat_3 faminc_cat)(connect diff_hat_4 faminc_cat)(connect diff_hat_5 faminc_cat), ///
       legend(label(1 "Excellent") label(2 "Very good") label(3 "Good") label(4 "Fair") label(5 "Poor")) ///
	   ytitle(Predicted Probability Differences) title(Differences in predicted health status) subtitle(between whites and blacks)

graph bar badhealth mort5, by(race_cat) legend(label(1 "Poor or fair health") label(2 "Died within 5 years of survey"))
