/* specurve - Specification Curve Analysis in Stata

    author: Mingze Gao (Macquarie University; University of Sydney)
    email: mingze.gao@mq.edu.au
 */
set matastrict on

capture program drop specurve

program specurve
  version 16.0
  syntax using/ [, OUTput outcmd DESCending Benchmark(real 0) /// 
    relativesize(real 0.6) ///
    scale(real 1) Width(real 6) Height(real 8) ///
    saving(passthru) ///
    title(passthru) ///
    name(passthru) ///
    ROUNDing(real 0.001) ///
    cmd(name) ///
    KEEPSINgletons ///
    NOBenchmark ///
	  NODependent ///
	  NOFocal ///
    NOFIXedeffect ///
    NOClustering ///
    NOCONDition ///
    NOCI99 ///
    NOCI95 ///
    yticks(int 5) ///
    ymin(real 0) ///
    ymax(real 0) ///
    controlvariablebygroup ///
    ]

  capture which reghdfe
  if _rc {
    display as result in smcl `"Please install package {it:reghdfe} to run this do-file;"'
    exit 199
  }
  capture which ivreghdfe 
  if _rc {
    display as result in smcl `"Please install package {it:ivreghdfe} in order to run this do-file;"' 
    exit 199
  }

  local nooutput = "`output'" != "output"
  local nooutcmd = "`outcmd'" != "outcmd"
  local descending = "`descending'" == "descending"
  local keepsingletons = "`keepsingletons'" == "keepsingletons"
  local controlvariablebygroup = "`controlvariablebygroup'" == "controlvariablebygroup"
  local nobenchmark = "`nobenchmark'" == "nobenchmark"
  local nodependent = "`nodependent'" == "nodependent"
  local nofocal = "`nofocal'" == "nofocal"
  local nofixedeffect = "`nofixedeffect'" == "nofixedeffect"
  local noclustering = "`noclustering'" == "noclustering"
  local nocondition = "`nocondition'" == "nocondition"
  local noci99 = "`noci99'" == "noci99"
  local noci95 = "`noci95'" == "noci95"
  local specmsize vsmall
  local specmsymbol o
  if (strlen("`cmd'")==0) local cmd "reghdfe"
  if "`cmd'" == "ppmlhdfe" {
    capture which ppmlhdfe 
    if _rc {
      display as result in smcl `"Please install package {it:ppmlhdfe} from SSC in order to run this do-file;"'
      exit 199
  }
  }

  mata: main("`using'", `nooutput', `keepsingletons')

  frame specurve {


    if (`descending') gsort -beta
    else gsort beta
    gen rank = _n
    qui: su beta, detail
    local beta_obs1 = `r(min)'
    local beta_median = `r(p50)'
    /* Stouffer's Z */
    gen z = -invnormal(pval/2)
    gen w = 1/sqrt(_N) // weight is square root of number of tests
    egen sumw = sum(w)
    egen sumzw = sum(z*w)
    gen z_stouffer = sumzw / sumw
    drop z w sumw sumzw
    su z_stouffer, meanonly
    local z_stouffer = `r(mean)'
    drop z_stouffer // TODO: this test is not consistent with Simonsohn, Simmons, and Nelson (2020) yet
    
    /* gen sig95 = (`benchmark' < lb95)  | (`benchmark' > ub95) */
    /* gen sig99 = (`benchmark' < lb99)  | (`benchmark' > ub99) */
    gen sig90 = pval <= 0.1
    gen sig95 = pval <= 0.05
    gen sig99 = pval <= 0.01
    qui: count
    local nspecs = r(N)
    qui: count if sig99==1
    local nsig99 = r(N)
    qui: count if sig95==1
    local nsig95 = r(N)
    qui: count if sig90==1
    local nsig90 = r(N)
    di "[specurve] `c(current_time)' - `nsig99' out of `c(N)' models have point estimates significant at 1% level."
    di "[specurve] `c(current_time)' - `nsig95' out of `c(N)' models have point estimates significant at 5% level."
    di "[specurve] `c(current_time)' - `nsig90' out of `c(N)' models have point estimates significant at 10% level."
    /* di "[specurve] `c(current_time)' - Median effect estimated across all specification is `beta_median'" */
    /* di "[specurve] `c(current_time)' - Stouffer's Z is `z_stouffer'" */
    /* di "[specurve] `c(current_time)' - Results saved in frame. Use {stata frame change specurve} to check. {stata frame change default} to restore." */

    /* Maybe, here, we process rhs_excl_focal. 
       Each value of rhs_excl_focal is currently viewed as a distinct spec.
       We may instead view it as concatenation of specs. 
     */
    if `controlvariablebygroup'==1 {
      quietly {
        split rhs_excl_focal, parse(", ") gen(rhs)
        reshape long rhs, i(model) j(rhs_g)
        drop if rhs==""
        bys rhs: egen idrhs = min(real(idrhs_excl_focal))
        /* Then, need to fix the value labels. */
        /* Interestingly and to our benefit, we only need to fix the labchoices
          for the control variables group. */
        su idrhs, meanonly
        forvalues v = `r(min)'/`r(max)' {
          preserve
          keep if idrhs == `v'
          local lab = rhs[1]
          restore
          label define labchoices `v' "`lab'", modify
        }
        tostring idrhs, replace
      }
      label var rhs "Control variables"
    }

    /* Number of lines in the lower panel (specificaitons) */
    local nylabs -1
    if `controlvariablebygroup'==1 local _varlist lhs focal rhs fe secluster cond
    else local _varlist lhs focal rhs_excl_focal fe secluster cond
    foreach v in `_varlist' {
        /* encode `v', gen(`v'_encoded) label(`v'_label) */
        cap gen `v'_encoded = real(id`v')
        label values `v'_encoded labchoices
        su `v'_encoded, meanonly
        /* conditions may be missing so that r(max) is undefined */
        if (!missing("`r(max)'")) {
          local nylabs = `nylabs' + `r(max)' - `r(min)' + 2
        }
    }
    
    /* Plotting */
    label var lhs "Dependent variable"
    label var focal "Focal variable"
    label var rhs_excl_focal "Control variables"
    label var fe "Fixed effects"
    label var secluster "Standard error clustering"
    label var cond "Condition"

    
    // Range of coeffs and CIs	
    su lb99, meanonly
    if (`nobenchmark'==0 & `benchmark' < `r(min)') local minlb `benchmark'
    else local minlb `r(min)'
    su ub99, meanonly
    if (`nobenchmark'==0 & `benchmark' > `r(max)') local maxub `benchmark'
    else local maxub `r(max)'
    if (`ymax' != 0) local maxub = `ymax'
    if (`ymin' != 0) local minlb = `ymin'
    local range = `maxub' - `minlb'
    if (`ymax' != 0 | `ymin' != 0) local rangescale = 1
    else local rangescale = 0.95
    local rangelg = `range' / `rangescale' // increase range a bit
    local ymin = `minlb' - (`rangelg'-`range')/2
    local ymax = `maxub' + (`rangelg'-`range')/2
    local ystep = (`ymax'-`ymin')/(`yticks'-1)
    local ndecimals = strlen(strofreal(`rounding'))-1
    // We want the upper panel coeffs to span about `relativesize' of the area
    // the lower panel specifications about (1-`relativesize') of the area
    // `nylabs' lines in the lower panel that should span 0.3*(ymax-ymin)
    // 0.3*(`ymax'-`ymin')/`nylabs' is step size
    local ysteplowerpanel = (1-`relativesize')*(`ymax'-`ymin')/`nylabs' 
    

    // Optionally turn off display of certain labels in the bottom panel 
    if `controlvariablebygroup'==1 local _varlist rhs
    else local _varlist rhs_excl_focal
    if (`nofocal'!=1) local _varlist focal `_varlist'
    if (`nodependent'!=1) local _varlist lhs `_varlist'
    if (`nofixedeffect'!=1) local _varlist `_varlist' fe
    if (`noclustering'!=1) local _varlist `_varlist' secluster
    if (`nocondition'!=1) local _varlist `_varlist' cond
    /* di "`_varlist'" */

    local offset 2
    foreach v in `_varlist' {
        su `v'_encoded, meanonly
        /* No condition specified leads to cond_encoded all missing */
        if (missing("`r(max)'")) continue
        local pos = `ymin' - (`offset') * `ysteplowerpanel'
        local labv: variable label `v' 
        local speclabs1 `speclabs1' `pos' "{bf:`labv'}"
        forval i=`r(min)'/`r(max)' {
            /* local lab`i' : label `v'_label `i'  */
            local lab`i' : label labchoices `i' 
            local pos = `ymin' - (`offset'+`i'-`r(min)'+1) * `ysteplowerpanel'
            local speclabs `speclabs' `pos' "`lab`i''"
        }
        qui: replace `v'_encoded = `ymin' - (`offset'+`v'_encoded-`r(min)'+1) * `ysteplowerpanel'
        local offset = `offset' + `r(max)'-`r(min)' + 2
    }
    if `controlvariablebygroup'==1 {
      gen rhs_excl_focal_encoded = rhs_encoded
    }
    di "[specurve] `c(current_time)' - Plotting specification curve..."

    /* whether to display benchmark line */
    if (`nobenchmark'==1) local benchmarklinestyle none
    else local benchmarklinestyle yxline
    if (`nobenchmark'==1) local benchmarklinelabelsize 0 
    else local benchmarklinelabelsize small

    if (`nobenchmark'==1) di "[specurve] `c(current_time)' - No display of benchmark line."
    if (`nodependent'==1) di "[specurve] `c(current_time)' - No display of dependent variable."
    if (`nofocal'==1) di "[specurve] `c(current_time)' - No display of focal variable."
    if (`nofixedeffect'==1) di "[specurve] `c(current_time)' - No display of fixed effects."
    if (`noclustering'==1) di "[specurve] `c(current_time)' - No display of standard error clustering."
    if (`nocondition'==1) di "[specurve] `c(current_time)' - No display of conditions."
    if (`noci99'==1) di "[specurve] `c(current_time)' - No display of 99% confidence intervals."
    if (`noci95'==1) di "[specurve] `c(current_time)' - No display of 95% confidence intervals."

    if (`noci99'==1) local _legendci99 " (hidden)"
    else local _legendci99 ""
    if (`noci95'==1) local _legendci95 " (hidden)"
    else local _legendci95 ""

    graph tw  ///
        (rbar ub99 lb99 rank if `noci99'==0, fcolor(gs12) fintensity(inten50) lcolor(gs12) lwidth(none)) /// 99% CI
        (rbar ub95 lb95 rank if `noci95'==0, fcolor(gs6) fintensity(inten40) lcolor(gs6) lwidth(none)) /// 95% CI
	    (scatter beta rank if pval<0.01, mcolor(blue) msymbol(o)  msize(small)) ///  
	    (scatter beta rank if 0.01<=pval & pval<0.05, mcolor(blue) msymbol(oh)  msize(small)) ///  
	    (scatter beta rank if 0.05<=pval & pval<0.1, mcolor(blue) msymbol(+)  msize(small)) ///  
	    (scatter beta rank if pval>=0.1, mcolor(red) msymbol(o)  msize(small)) ///  
        (scatter lhs_encoded rank if `nodependent'==0, msize(`specmsize') msymbol(`specmsymbol'))  /// 
        (scatter focal_encoded rank if `nofocal'==0, msize(`specmsize') msymbol(`specmsymbol'))  ///
        (scatter rhs_excl_focal_encoded rank, msize(`specmsize') msymbol(`specmsymbol'))  ///
        (scatter fe_encoded rank if `nofixedeffect'==0, msize(`specmsize') msymbol(`specmsymbol'))  ///
        (scatter secluster_encoded rank if `noclustering'==0, msize(`specmsize') msymbol(`specmsymbol'))  ///
        (scatter cond_encoded rank if `nocondition'==0, msize(`specmsize') msymbol(`specmsymbol'))  ///
      , legend(rows(3) rowgap(1) colfirst order(3 "Point estimate ({it:p}<0.01)" 4 "Point estimate ({it:p}<0.05)" 5 "Point estimate ({it:p}<0.1)" 6 "Point estimate ({it:p}{&ge}0.1)" 1 "99% CI`_legendci99'" 2 "95% CI`_legendci95'") region(lcolor(white)) ///
	    pos(12) ring(1) size(vsmall) symysize(vsmall) symxsize(vsmall)) ///
      xtitle("") ytitle("") ///
      yline(`benchmark', lstyle(`benchmarklinestyle')) ///
      yscale() xscale() ///
      xlab(minmax, noticks labsize(small))  /// 
      ylab(`ymin'(`ystep')`ymax', angle(0) nogrid labsize(small) format(%9.`ndecimals'fc)) ///
      ylab(`benchmark' "`benchmark'", add custom angle(0) nogrid notick labsize(`benchmarklinelabelsize') labcolor(cranberry)) ///
      ylab(`speclabs1', add custom angle(0) nogrid notick labsize(tiny)) ///
      ylab(`speclabs', add custom angle(0) nogrid notick labsize(tiny)) ///
      graphregion(fcolor(white) lcolor(white)) ///
      plotregion(fcolor(white) lcolor(white)) ///
      scale(`scale') ///
      xsize(`width') ysize(`height') ///
      `saving' `title' `name'

    /* clean up */
    drop *_encoded id* 
    if `controlvariablebygroup' {
      drop rhs_g rhs
      qui duplicates drop
    }
  }

  di "[specurve] `c(current_time)' - Completed."
  di "[specurve] use {stata frame change specurve} to see results"
  di "[specurve] use {stata frame change default} to switch back to current frame"
end

mata:

struct specification {
  /* vars */
  string scalar lhs
  string scalar focal_var
  string scalar rhs_excl_focal
  string scalar condition
  string scalar fixed_effects
  string scalar standard_error_clustering
  /* labels */
  string scalar label_lhs
  string scalar label_focal_var
  string scalar label_rhs_excl_focal
  string scalar label_condition
  string scalar label_fixed_effects
  string scalar label_standard_error_clustering
  /* label id for preserving orders */
  string scalar label_lhs_id
  string scalar label_focal_var_id
  string scalar label_rhs_excl_focal_id
  string scalar label_condition_id
  string scalar label_fixed_effects_id
  string scalar label_se_clustering_id
  /* misc */
  string scalar stata_cmd
  string scalar configstr
}

struct config {
  /* which group this config belongs to, 
     e.g., "Dependent Variable", "Focal Variable", etc. */
  string scalar group
  /* the label of the config */
  string scalar label
  /* the variable(s) for the config */
  string scalar variables
  /* the order of the config in the group */
  real scalar id
}

struct group {
  string scalar name
  real scalar nlabels
}

void main(string scalar filename, real scalar nooutput, real scalar keepsingletons) {
  struct config scalar config
  struct config vector choices, conditions
  struct specification vector specs
  choices = J(200, 1, config)
  conditions = J(200, 1, config)
  /* Stata frame to store results */
  stata("cap frame drop specurve")
  stata("mkf specurve double(beta lb95 ub95 lb99 ub99 pval) int(obs) strL(model lhs focal rhs_excl_focal fe secluster cond) str1024(cmd) str8(idlhs idfocal idrhs_excl_focal idfe idsecluster idcond)")
  st_framecurrent("specurve")
  stata(sprintf("label define labchoices 0 %s%s, replace", char(34), char(34)))
  /* procedures */
  read_configuration(filename, &choices, &conditions)
  specs = compose_all_specifications(choices, conditions)
  st_framecurrent("default")
  estimate(&specs, nooutput, keepsingletons)
}

void estimate(pointer(struct specification vector) scalar specs,
              real scalar nooutput,
              real scalar keepsingletons) {
  real scalar i, totalspecs
  string scalar cmd
  struct specification scalar spec
  totalspecs = length(*specs)
  printf("[specurve] %s - %g total specifications to estimate.\n", 
           c("current_time"), totalspecs)
  for (i=1; i<=totalspecs; i++) {
    printf("[specurve] %s - Estimating model %g of %g\n", 
           c("current_time"), i, totalspecs)
    spec = (*specs)[i]
    cmd = sprintf("%s %s %s %s", 
                  spec.stata_cmd,
                  spec.lhs,
                  spec.focal_var,
                  spec.rhs_excl_focal)
    /* conditions */
    if (strlen(spec.condition))
      cmd = sprintf("%s if (%s),", cmd, spec.condition)
    else
      cmd = sprintf("%s,", cmd)
    /* fixed effects */
    if (strlen(spec.fixed_effects))
      cmd = sprintf("%s absorb(%s)", cmd, spec.fixed_effects)
    else {
      if (spec.stata_cmd == "reghdfe") {
        cmd = sprintf("%s noa", cmd)
      } else if (spec.stata_cmd == "ivreghdfe") {
        cmd = sprintf("%s ", cmd)
      } else if (spec.stata_cmd == "ppmlhdfe") {
        cmd = sprintf("%s ", cmd)
      }
    }
    /* standard error clustering */
    if (strlen(spec.standard_error_clustering)) {
      if (spec.stata_cmd == "reghdfe") {
        cmd = sprintf("%s vce(cluster %s)", cmd, spec.standard_error_clustering)
      } else if (spec.stata_cmd == "ivreghdfe") {
        cmd = sprintf("%s cluster(%s)", cmd, spec.standard_error_clustering)
      } else if (spec.stata_cmd == "ppmlhdfe") {
        cmd = sprintf("%s vce(cluster %s)", cmd, spec.standard_error_clustering)
      }
    }
    /* reghdfe options */
    if (spec.stata_cmd == "reghdfe" | spec.stata_cmd == "ppmlhdfe") {
      if (keepsingletons) {
        cmd = sprintf("%s keepsingletons", cmd)
      }
    }
    /* execute the Stata command */
    if (strlen(st_local("outcmd"))) printf("%s\n", cmd)
    stata(cmd, nooutput)
    /* results */
    string scalar fvar
    if (spec.stata_cmd == "reghdfe") {
        fvar = spec.focal_var
    } else if (spec.stata_cmd == "ivreghdfe") {
        /* spec.focal_var is like "(fvar=iv)" */
        fvar = substr(spec.focal_var, 2, strpos(spec.focal_var, "=")-2)
        stata(sprintf("local est = _b[%s]", fvar))
    } else if (spec.stata_cmd == "ppmlhdfe") {
        fvar = spec.focal_var
    }
    spec.focal_var = fvar /* Maybe not to overwrite? */
    stata(sprintf("local est = _b[%s]", spec.focal_var))
    if (spec.stata_cmd == "reghdfe" | spec.stata_cmd == "ivreghdfe") {
      stata(sprintf("local lb95 = _b[%s] - invttail(e(df_r),0.025)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local ub95 = _b[%s] + invttail(e(df_r),0.025)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local lb99 = _b[%s] - invttail(e(df_r),0.005)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local ub99 = _b[%s] + invttail(e(df_r),0.005)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local pval = 2*ttail(e(df_r), abs(_b[%s]/_se[%s]))",
                    spec.focal_var, spec.focal_var))
    } else if (spec.stata_cmd == "ppmlhdfe") {
      stata(sprintf("local lb95 = _b[%s] + invnormal(0.025)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local ub95 = _b[%s] - invnormal(0.025)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local lb99 = _b[%s] + invnormal(0.005)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local ub99 = _b[%s] - invnormal(0.005)*_se[%s]", 
                    spec.focal_var, spec.focal_var))
      stata(sprintf("local pval = 2*normal(-abs(_b[%s]/_se[%s]))",
                    spec.focal_var, spec.focal_var))
    }
    string scalar framepost, model_id
    model_id = sprintf("model %g", i)
    framepost = "frame post specurve "
    framepost = sprintf("%s (%s) ", framepost, st_local("est"))
    framepost = sprintf("%s (%s) ", framepost, st_local("lb95"))
    framepost = sprintf("%s (%s) ", framepost, st_local("ub95"))
    framepost = sprintf("%s (%s) ", framepost, st_local("lb99"))
    framepost = sprintf("%s (%s) ", framepost, st_local("ub99"))
    framepost = sprintf("%s (%s) ", framepost, st_local("pval"))
    framepost = sprintf("%s (%g) ", framepost, st_numscalar("e(N)"))
    framepost = sprintf("%s (%s) ", framepost, _wrap(model_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_lhs))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_focal_var))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_rhs_excl_focal))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_fixed_effects))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_standard_error_clustering))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_condition))
    framepost = sprintf("%s (%s) ", framepost, _wrap(cmd))
    /* add label ids */
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_lhs_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_focal_var_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_rhs_excl_focal_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_fixed_effects_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_se_clustering_id))
    framepost = sprintf("%s (%s)", framepost, _wrap(spec.label_condition_id))
    stata(framepost)
  }
}

string scalar _wrap(string scalar w) {
  return(sprintf("%s%s%s", char(34), w, char(34)))
}


struct specification vector compose_all_specifications(
                                struct config vector choices, 
                                struct config vector conditions) {
  /* number of distinct groups from both CHOICES and CONDITIONS */
  string vector groupnames, uniquegroups
  struct group vector groupvec
  struct group scalar group
  groupnames = J(length(choices)+length(conditions),1,"")
  real scalar i, j, k
  for (i=1; i<=length(choices); i++) 
    groupnames[i] = choices[i].group
  for (i=1; i<=length(conditions); i++) 
    groupnames[i+length(choices)] = conditions[i].group
  uniquegroups = uniqrows(groupnames)
  real scalar hasemptygroupname
  hasemptygroupname = 0
  for (i=1; i<=length(uniquegroups); i++) {
    if (uniquegroups[i]=="") {
      hasemptygroupname = 1
      break
    }
  }
  if (hasemptygroupname)
    groupvec = J(length(uniquegroups)-1,1,group)
  else
    groupvec = J(length(uniquegroups),1,group)
  /* group name and number of configs under each group */
  k = 0
  for (i=1; i<=length(uniquegroups); i++) {
    if (uniquegroups[i] == "") continue
    k = k + 1
    groupvec[k].name = uniquegroups[i]
    groupvec[k].nlabels = 0
    for (j=1; j<=length(choices); j++) {
      if (choices[j].group==groupvec[k].name) 
        groupvec[k].nlabels = groupvec[k].nlabels + 1
    }
    for (j=1; j<=length(conditions); j++) {
      if (conditions[j].group==groupvec[k].name) 
        groupvec[k].nlabels = groupvec[k].nlabels + 1
    }
  }

  /* find all combinations */
  real scalar numspecs
  numspecs = 1
  for (i=1; i<=length(groupvec); i++) {
    numspecs = numspecs * groupvec[i].nlabels
  }
  /* printf("%g total specifications to estimate.\n", numspecs) */

  struct specification scalar spec
  struct specification vector specs
  spec.stata_cmd = st_local("cmd")
  specs = J(numspecs, 1, spec)

  cartesian_prod(1, groupvec, &specs, 1, "")

  /* making specifications */
  real scalar groupnum, labelnum
  string vector conftokens, conftoken
  string scalar groupname, labelname, configvar, labelId
  for (k=1; k<=length(specs); k++) {
    /* specs[k].configstr is like: "1-2 2-1 3-5 4-1 5-2 6-2"
       group 1 - label 2
       group 2 - label 1
       ...
     */
    conftokens = tokens(specs[k].configstr)
    for (i=1; i<=length(conftokens); i++) {
      conftoken = tokens(conftokens[i], "-")
      groupnum = strtoreal(conftoken[1])
      labelnum = strtoreal(conftoken[3])
      groupname = groupvec[groupnum].name
      labelname = get_config(labelnum, groupname, &choices, &conditions, "lab")
      configvar = get_config(labelnum, groupname, &choices, &conditions, "var")
      /* the order of the label in the group */
      labelId =  get_config(labelnum, groupname, &choices, &conditions, "labId")
      /* printf("  %s %s\n", groupname, labelname) */
      /* write into the specs */
      make_specification(&(specs[k]), groupname, labelname, configvar, labelId)
    }

  }
  return(specs)
}


void make_specification(pointer(struct specification scalar) scalar spec,
                        string scalar groupname, string scalar label,
                        string scalar configvar,
                        string scalar labelId) {
  if (strpos(strlower(groupname), "focal variable")) {
    /* handle iv specification (var=iv) */
    (*spec).focal_var = configvar
    (*spec).label_focal_var = label
    /* focal var's label id in choices */
    (*spec).label_focal_var_id = labelId // add this field to struct specification
  }
  else if (strpos(strlower(groupname), "dependent variable")) {
    (*spec).lhs = configvar
    (*spec).label_lhs = label
    (*spec).label_lhs_id = labelId 
  }
  else if (strpos(strlower(groupname), "control variables")) {
    (*spec).rhs_excl_focal = configvar
    (*spec).label_rhs_excl_focal = label
    (*spec).label_rhs_excl_focal_id = labelId 
  }
  else if (strpos(strlower(groupname), "fixed effects")) {
    (*spec).fixed_effects = configvar
    (*spec).label_fixed_effects = label
    (*spec).label_fixed_effects_id = labelId 
  }
  else if (strpos(strlower(groupname), "standard error clustering")) {
    (*spec).standard_error_clustering = configvar
    (*spec).label_standard_error_clustering = label
    (*spec).label_se_clustering_id = labelId 
  }
  /* condition, if not one of the choices */
  else {
    (*spec).condition = configvar
    (*spec).label_condition = label
    (*spec).label_condition_id = labelId 
  }
}


string scalar get_config(real scalar id, string scalar groupname,
                         pointer(struct config vector) scalar choices,
                         pointer(struct config vector) scalar conditions,
                         string scalar returnval) {
  real scalar i, k
  k = 0
  for (i=1; i<=length(*choices); i++) {
    if ((*choices)[i].group == groupname) k = k + 1
    if (k == id) 
      if (returnval=="lab") return((*choices)[i].label)
      else if (returnval=="var") return((*choices)[i].variables)
      else if (returnval=="labId") return(strofreal(((*choices)[i].id)))
  }
  k = 0
  for (i=1; i<=length(*conditions); i++) {
    if ((*conditions)[i].group == groupname) k = k + 1
    if (k == id)
      if (returnval=="lab") return((*conditions)[i].label)
      else if (returnval=="var") return((*conditions)[i].variables)
      else if (returnval=="labId") return(strofreal((*conditions)[i].id))
  }
  return("")
}

void cartesian_prod(real scalar i, struct group vector groupvec, 
                    pointer(struct specification vector) scalar specs,
                    real scalar depth,
                    string scalar configstr) {
  real scalar j, k
  string scalar cnext
  if (depth>length(groupvec)) {
    for (k=1; k<=length(*specs); k++) {
      if ((*specs)[k].configstr == "") {
        (*specs)[k].configstr = configstr
        break
      }
    }
    return
  }
  for (j=1; j<=groupvec[i].nlabels; j++) {
    cnext = configstr + strofreal(i) + "-" +  strofreal(j) + " "
    cartesian_prod(i+1, groupvec, specs, depth+1, cnext)
  }
}

void read_configuration(string scalar filename,
                        pointer(struct config vector) scalar choices,
                        pointer(struct config vector) scalar conditions) {

  /* declariations and inits */
  struct config scalar    config
  real scalar             input_fh
  string scalar           line, groupname
  real scalar             isProcessingChocies, isProcessingConditions
  real scalar             numChoices, numConditions
  real scalar             comment_pos
  isProcessingChocies     = 0
  isProcessingConditions  = 0
  numChoices              = 0
  numConditions           = 0

  input_fh = fopen(filename, "r")

  /* process line by line */
  while ( (line=fget(input_fh)) != J(0,0,"") ) {
    /* remove comments and trim line */
    /* this line starts with a hashtag: comment line */
    if (strpos(strtrim(line), "#") == 1) continue
    /* this hashtag # has a leading space, ie. it marks inline comment */
    comment_pos = strpos(line, " #")
    if (comment_pos) {
      line = substr(line, 1, comment_pos-1)
    }
    line = strtrim(line)
    if (!strlen(line)) continue
    /* check if is processing CHOICES */
    if (strpos(strlower(line), "choices") & length(tokens(line))==1) {
      isProcessingConditions = 0
      isProcessingChocies = 1
    }
    /* check if is processing CONDITIONS */
    else if (strpos(strlower(line), "conditions") & length(tokens(line))==1) {
      isProcessingChocies = 0
      isProcessingConditions = 1
    }

    if (isProcessingChocies) {
      if (strpos(line, "-") != 1) {
        groupname = line
      } else {
        config = process_config_line(groupname, line, *choices, *conditions, 1)
        numChoices = numChoices + 1
        (*choices)[numChoices] = config
      }
    }
    else if (isProcessingConditions) {
      if (strpos(line, "-") != 1) {
        groupname = line
      } else {
        config = process_config_line(groupname, line, *choices, *conditions, 0)
        numConditions = numConditions + 1
        (*conditions)[numConditions] = config
      }
    }
  }

  fclose(input_fh)
}

struct config scalar process_config_line(string scalar group, 
                                         string scalar line,
                        struct config vector choices,
                        struct config vector conditions,
                        real scalar processChoices) {
  /* This function reads a line and return the config (group, label and vars) */
  struct config scalar config
  /* remove leading "-" which marks the line as a config alternative */
  line = strtrim(substr(line, 2, strlen(line)-1))
  /* parse label and variables */
  config.group = group
  config.label = substr(line, 1, strpos(line, ":")-1)
  config.variables = strtrim(substr(line, strpos(line, ":")+1, strlen(line)-1))
  /* keep track of the order of labels in each group */
  /* if a label is never seen, assign it id = nlabels in the group + 1 */
  real scalar labelHasBeenUsed 
  real scalar maxLabelId 
  real scalar i
  labelHasBeenUsed = 0
  maxLabelId = 0
  if (processChoices) {
    for (i=1; i<=length(choices); i++) {
      if (choices[i].label == "") break
      if (maxLabelId<choices[i].id) maxLabelId = choices[i].id
      if (choices[i].label == config.label && choices[i].group == config.group) {
        labelHasBeenUsed = 1
        config.id = choices[i].id
        break
      }
    }
  } else {
    real scalar maxLabelChoicesId
    maxLabelChoicesId = 0
    for (i=1; i<=length(choices); i++) {
      if (choices[i].label == "") break
      if (maxLabelChoicesId<choices[i].id) maxLabelChoicesId= choices[i].id
    }

    for (i=1; i<=length(conditions); i++) {
      if (conditions[i].label == "") break
      if (maxLabelId<conditions[i].id) maxLabelId = conditions[i].id
      if (conditions[i].label == config.label && conditions[i].group == config.group) {
        labelHasBeenUsed = 1
        config.id = conditions[i].id
        break
      }
    }

    if (maxLabelId <= maxLabelChoicesId) {
      maxLabelId = maxLabelId + maxLabelChoicesId
    }
  }
  if (labelHasBeenUsed == 0) {
    config.id = maxLabelId + 1
  }
  string scalar lab
  lab = sprintf("label define labchoices %s %s%s%s, modify", strofreal(config.id), char(34), config.label, char(34))
  stata(lab)
  
  return(config)
}

end