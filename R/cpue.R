# Readable toy analyses: Poisson GLM CPUE and a one-parameter Schaefer fit.

describe_data <- function(sets, catches) {
  check_sets(sets)
  check_catches(catches)
  vessels <- sort(unique(rows_values(sets, "vessel")))
  years <- sort(unique(rows_values(sets, "year")))
  annual <- lapply(years, function(year) {
    rows <- Filter(function(row) row$year == year, sets)
    catch <- catches[[match(year, rows_values(catches, "year"))]]$catch_t
    counts <- setNames(lapply(vessels, function(vessel) {
      sum(rows_values(rows, "vessel") == vessel)
    }), vessels)
    list(year = year, observations = length(rows),
         hooks = sum(rows_values(rows, "hooks")),
         catch_n = sum(rows_values(rows, "catch_n")), catch_t = catch,
         zero_catch_percent = 100 * mean(rows_values(rows, "catch_n") == 0),
         vessels = counts)
  })
  fields <- list(
    list(name = "set_id", meaning = "Unique fishing observation", type = "text"),
    list(name = "year", meaning = "Year of fishing", type = "integer"),
    list(name = "vessel", meaning = "Synthetic vessel identifier", type = "text"),
    list(name = "hooks", meaning = "Fishing effort (hooks)", type = "integer"),
    list(name = "catch_n", meaning = "Catch in number of fish", type = "integer"))
  list(annual = annual, vessels = json_array(vessels), observations = length(sets), fields = fields)
}

cpue <- function(sets, vessel_effect = TRUE, min_hooks = 0) {
  check_sets(sets)
  rows <- Filter(function(row) row$hooks >= min_hooks, sets)
  check_sets(rows)
  years <- sort(unique(rows_values(rows, "year")))
  vessels <- sort(unique(rows_values(rows, "vessel")))
  data <- data.frame(year = factor(rows_values(rows, "year"), levels = years),
                     vessel = factor(rows_values(rows, "vessel"), levels = vessels),
                     hooks = rows_values(rows, "hooks"),
                     catch_n = rows_values(rows, "catch_n"))
  require_condition(all(tapply(data$catch_n, data$year, sum) > 0) &&
                      all(tapply(data$catch_n, data$vessel, sum) > 0),
                    "The illustrative GLM requires positive annual and vessel totals.")
  formula <- if (vessel_effect && length(vessels) > 1) {
    catch_n ~ year + vessel + offset(log(hooks / 1000))
  } else {
    catch_n ~ year + offset(log(hooks / 1000))
  }
  fit <- stats::glm(formula, data = data, family = stats::poisson(),
                    control = stats::glm.control(epsilon = 1e-10, maxit = 100))
  require_condition(fit$converged, "The CPUE GLM did not converge.")
  reference <- data.frame(year = factor(years, levels = years),
                          vessel = factor(vessels[1], levels = vessels), hooks = 1000)
  predicted <- as.numeric(stats::predict(fit, newdata = reference, type = "response"))
  index <- predicted / predicted[1]
  residual <- max(abs(tapply(stats::fitted(fit), data$year, sum) /
                       tapply(data$catch_n, data$year, sum) - 1))
  require_condition(all(is.finite(index) & index > 0) && residual < 1e-7,
                    "The CPUE GLM score check failed.")
  list(series = lapply(seq_along(years), function(i) list(year = years[i], index = index[i])),
       sets_used = length(rows), sets_excluded = length(sets) - length(rows),
       method = if (vessel_effect) "Poisson GLM: year + vessel" else "Poisson GLM: year only",
       iterations = fit$iter, converged = fit$converged,
       deviance = fit$deviance, score_residual = residual,
       reference_vessel = vessels[1], effort_unit = "1000 hooks")
}

