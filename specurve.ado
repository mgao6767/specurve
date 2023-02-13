set matastrict on

capture program drop specurve

program specurve
  syntax using/ [, OUTput DESCending Benchmark(real 0)]

  local nooutput = "`output'" != "output"
  local descending = "`descending'" == "descending"
  local specmsize vsmall
  local specmsymbol o

  mata: main("`using'", `nooutput')

  frame specurve_res {
    if (`descending') gsort -beta
    else gsort beta
    gen rank = _n
    su beta, meanonly
    local beta_obs1 = `r(min)'
    gen sig95 = (`benchmark' < lb95)  | (`benchmark' > ub95)
    gen sig99 = (`benchmark' < lb99)  | (`benchmark' > ub99)
    qui: count
    local nspecs = r(N)
    qui: count if sig99==1
    local nsig99 = r(N)
    qui: count if sig95==1
    local nsig95 = r(N)
    di "[specurve] `c(current_time)' - `nsig99' out of `c(N)' models have point estimates significant at 1% level."
    di "[specurve] `c(current_time)' - `nsig95' out of `c(N)' models have point estimates significant at 5% level."

    /* Plotting */
    label var lhs "Dependent variable"
    label var focal "Focal variable"
    label var rhs_excl_focal "Control variables"
    label var fe "Fixed effects"
    label var secluster "Standard error clustering"
    label var cond "Condition"

    /* Number of lines in the lower panel (specificaitons) */
    local nylabs -1
    foreach v in lhs focal rhs_excl_focal fe secluster cond {
        encode `v', gen(`v'_encoded) label(`v'_label)
        su `v'_encoded, meanonly
        forval i=1/`r(max)' {
          local ++nylabs
        }
    }
    // Range of coeffs and CIs	
    su lb99, meanonly
    if (`benchmark' < `r(min)') local minlb `benchmark'
    else local minlb `r(min)'
    su ub99, meanonly
    if (`benchmark' > `r(max)') local maxub `benchmark'
    else local maxub `r(max)'
    local range = `maxub' - `minlb'
    local rangelg = `range' / 0.95 // increase range a bit
    local ymin = round(`minlb' - (`rangelg'-`range')/2, 0.001) // no rounding?
    local ymax = round(`maxub' + (`rangelg'-`range')/2, 0.001)
    local ystep = round((`ymax'-`ymin')/4, 0.001) 
    // We want the upper panel coeffs to span about 70% of the area
    // the lower panel specifications about 30% of the area
    // `nylabs' lines in the lower panel that should span 0.3*(ymax-ymin)
    // 0.3*(`ymax'-`ymin')/`nylabs' is step size
    local ysteplowerpanel = 0.3*(`ymax'-`ymin')/`nylabs' 
    
    local offset 2
    foreach v in lhs focal rhs_excl_focal fe secluster cond {
        su `v'_encoded, meanonly
        forval i=1/`r(max)' {
            local lab`i' : label `v'_label `i' 
            local pos = `ymin' - (`offset'+`i') * `ysteplowerpanel'
            local speclabs `speclabs' `pos' "`lab`i''"
        }
        qui: replace `v'_encoded = `ymin' - (`offset'+`v'_encoded) * `ysteplowerpanel'
        local offset = `offset' + `r(max)'
    }

    di "[specurve] `c(current_time)' - Plotting specification curve..."
    tempname specurve_p
    tw  ///
        (rbar ub99 lb99 rank, fcolor(gs12) fintensity(inten50) lcolor(gs12) lwidth(none)) /// 99% CI
        (rbar ub95 lb95 rank, fcolor(gs6) fintensity(inten40) lcolor(gs6) lwidth(none)) /// 95% CI
	    (scatter beta rank if sig99==1, mcolor(blue) msymbol(o)  msize(small)) ///  
	    (scatter beta rank if sig99==0, mcolor(red) msymbol(oh)  msize(small)) ///  
        (scatter lhs_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
        (scatter focal_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
        (scatter rhs_excl_focal_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
        (scatter fe_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
        (scatter secluster_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
        (scatter cond_encoded rank, msize(`specmsize') msymbol(`specmsymbol')) ///
      , legend(order(3 "Point estimate (significant at 1% level)" 1 "99% CI" 2 "95% CI") region(lcolor(white)) ///
	    pos(12) ring(1) rows(1) size(small) symysize(small) symxsize(small)) ///
      xtitle("") ytitle("") ///
      yline(`benchmark') ///
      yscale() xscale() ///
      xlab(minmax, noticks labsize(small))  /// 
      ylab(`ymin'(`ystep')`ymax', angle(0) nogrid labsize(small)) ///
      ylab(`benchmark' "`benchmark'", add custom angle(0) nogrid notick labsize(small) labcolor(cranberry)) ///
      ylab(`speclabs', add custom angle(0) nogrid notick labsize(tiny)) ///
      graphregion(fcolor(white) lcolor(white)) ///
      plotregion(fcolor(white) lcolor(white)) ///
      name("`specurve_plot'",replace) 
  }

  di "[specurve] `c(current_time)' - Completed."
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
}

struct group {
  string scalar name
  real scalar nlabels
}

void main(string scalar filename, real scalar nooutput) {
  struct config scalar config
  struct config vector choices, conditions
  struct specification vector specs
  choices = J(200, 1, config)
  conditions = J(200, 1, config)
  /* procedures */
  read_configuration(filename, &choices, &conditions)
  specs = compose_all_specifications(choices, conditions)
  estimate(&specs, nooutput)
}

void estimate(pointer(struct specification vector) scalar specs,
              real scalar nooutput) {
  real scalar i, totalspecs
  string scalar cmd
  struct specification scalar spec
  totalspecs = length(*specs)
  printf("[specurve] %s - %g total specifications to estimate.\n", 
           c("current_time"), totalspecs)
  /* Stata frame to store results */
  stata("cap frame drop specurve_res")
  stata("mkf specurve_res double(beta lb95 ub95 lb99 ub99) int(obs) str32(model lhs focal rhs_excl_focal fe secluster cond) str1024(cmd)")
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
      cmd = sprintf("%s if (%s)", cmd, spec.condition)
    /* fixed effects */
    if (strlen(spec.fixed_effects))
      cmd = sprintf("%s, absorb(%s)", cmd, spec.fixed_effects)
    else
      cmd = sprintf("%s, noa", cmd)
    /* standard error clustering */
    if (strlen(spec.standard_error_clustering))
      cmd = sprintf("%s vce(cluster %s)", cmd, spec.standard_error_clustering)
    /* execute the Stata command */
    stata(cmd, nooutput)
    /* results */
    /* real scalar _b_focal_var = st_matrix("e(b)")[1] */
    stata(sprintf("local est = _b[%s]", spec.focal_var))
    stata(sprintf("local lb95 = _b[%s] - invttail(e(df_r),0.025)*_se[%s]", 
                  spec.focal_var, spec.focal_var))
    stata(sprintf("local ub95 = _b[%s] + invttail(e(df_r),0.025)*_se[%s]", 
                  spec.focal_var, spec.focal_var))
    stata(sprintf("local lb99 = _b[%s] - invttail(e(df_r),0.005)*_se[%s]", 
                  spec.focal_var, spec.focal_var))
    stata(sprintf("local ub99 = _b[%s] + invttail(e(df_r),0.005)*_se[%s]", 
                  spec.focal_var, spec.focal_var))
    string scalar framepost, model_id
    model_id = sprintf("model %g", i)
    framepost = "frame post specurve_res "
    framepost = sprintf("%s (%s) ", framepost, st_local("est"))
    framepost = sprintf("%s (%s) ", framepost, st_local("lb95"))
    framepost = sprintf("%s (%s) ", framepost, st_local("ub95"))
    framepost = sprintf("%s (%s) ", framepost, st_local("lb99"))
    framepost = sprintf("%s (%s) ", framepost, st_local("ub99"))
    framepost = sprintf("%s (%g) ", framepost, st_numscalar("e(N)"))
    framepost = sprintf("%s (%s) ", framepost, _wrap(model_id))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_lhs))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_focal_var))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_rhs_excl_focal))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_fixed_effects))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_standard_error_clustering))
    framepost = sprintf("%s (%s) ", framepost, _wrap(spec.label_condition))
    framepost = sprintf("%s (%s)", framepost, _wrap(cmd))
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
  spec.stata_cmd = "reghdfe"
  specs = J(numspecs, 1, spec)

  cartesian_prod(1, groupvec, &specs, 1, "")

  /* making specifications */
  real scalar groupnum, labelnum
  string vector conftokens, conftoken
  string scalar groupname, labelname, configvar
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
      /* printf("  %s %s\n", groupname, labelname) */
      /* write into the specs */
      make_specification(&(specs[k]), groupname, labelname, configvar)
    }

  }
  return(specs)
}


void make_specification(pointer(struct specification scalar) scalar spec,
                        string scalar groupname, string scalar label,
                        string scalar configvar) {
  if (strpos(strlower(groupname), "focal variable")) {
    (*spec).focal_var = configvar
    (*spec).label_focal_var = label
  }
  else if (strpos(strlower(groupname), "dependent variable")) {
    (*spec).lhs = configvar
    (*spec).label_lhs = label
  }
  else if (strpos(strlower(groupname), "control variables")) {
    (*spec).rhs_excl_focal = configvar
    (*spec).label_rhs_excl_focal = label
  }
  else if (strpos(strlower(groupname), "fixed effects")) {
    (*spec).fixed_effects = configvar
    (*spec).label_fixed_effects = label
  }
  else if (strpos(strlower(groupname), "standard error clustering")) {
    (*spec).standard_error_clustering = configvar
    (*spec).label_standard_error_clustering = label
  }
  /* condition, if not one of the choices */
  else {
    (*spec).condition = configvar
    (*spec).label_condition = label
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
  }
  k = 0
  for (i=1; i<=length(*conditions); i++) {
    if ((*conditions)[i].group == groupname) k = k + 1
    if (k == id)
      if (returnval=="lab") return((*conditions)[i].label)
      else if (returnval=="var") return((*conditions)[i].variables)
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
    comment_pos = strpos(line, "#")
    if (comment_pos)
      line = substr(line, 1, comment_pos-1)
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
        config = process_config_line(groupname, line)
        numChoices = numChoices + 1
        (*choices)[numChoices] = config
      }
    }
    else if (isProcessingConditions) {
      if (strpos(line, "-") != 1) {
        groupname = line
      } else {
        config = process_config_line(groupname, line)
        numConditions = numConditions + 1
        (*conditions)[numConditions] = config
      }
    }
  }

  fclose(input_fh)
}

struct config scalar process_config_line(string scalar group, 
                                         string scalar line) {
  /* This function reads a line and return the config (group, label and vars) */
  struct config scalar config
  /* remove leading "-" which marks the line as a config alternative */
  line = strtrim(substr(line, 2, strlen(line)-1))
  /* parse label and variables */
  config.group = group
  config.label = substr(line, 1, strpos(line, ":")-1)
  config.variables = strtrim(substr(line, strpos(line, ":")+1, strlen(line)-1))
  return(config)
}

end