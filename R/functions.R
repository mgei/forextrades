#' Get longer format trades
#'
#' @param trades trade data
#' @param col_opendate default `"Open Date"`
#' @param col_closedate default `"Close Date"`
#' @param col_openprice default `"Open Price"`
#' @param col_closeprice default `"Close Price"`
#' @param cols_to_keep columns to keep, default `c("Lots", "Action", "Profit")`
#'
#' @return long trade data
#' @export
#'
#' @examples
#' trades |>
#'   filter(Action %in% c("Buy", "Sell")) |>
#'   trades_long()
trades_long <- function(trades,
                        col_opendate = "Open Date",
                        col_closedate = "Close Date",
                        col_openprice = "Open Price",
                        col_closeprice = "Close Price",
                        cols_to_keep = c("Lots", "Action", "Profit")) {
  trades |>
    select(any_of(c(cols_to_keep, col_opendate, col_closedate, col_openprice, col_closeprice))) |>
    mutate(id = row_number()) |>
    pivot_longer(c(col_opendate, col_closedate), values_to = "datetime") |>
    mutate(Trade = ifelse(name == col_opendate, "open", "close"),
           price = ifelse(Trade == "open", !!as.name(col_openprice), !!as.name(col_closeprice)))
}

#' Compute net position and profit
#'
#' @param trades_l long trade data, normally created with `trades_long()`
#' @param lot_size standard lot size is 100000
#' @param col_buysell default `"Action"`
#'
#' @return trades_l but with position and profit columns
#' @export
#'
#' @examples # will follow
net_position <- function(trades_l,
                         lot_size = 100000,
                         col_buysell = "Action") {
  trades_l |>
    arrange(datetime) |>
    mutate(position = case_when(!!as.name(col_buysell) == "Buy" & Trade == "open" ~ Lots,
                                !!as.name(col_buysell) == "Buy" & Trade == "close" ~ -Lots,
                                !!as.name(col_buysell) == "Sell" & Trade == "open" ~ -Lots,
                                !!as.name(col_buysell) == "Sell" & Trade == "close" ~ Lots),
           position_net = cumsum(position),
           price_chg = (price - lag(price, default = first(price))) * lot_size,  # Change in price in terms of pips
           profit_from_change = lag(position_net, default = 0) * price_chg,  # profit due to change in price
           cum_profit = cumsum(profit_from_change))
}

#' Get FX prices from FMP
#'
#' @param pair e.g. `"EURUSD"`
#' @param frequency e.g. `"1min"`
#' @param from date
#' @param to date
#' @param apikey API key for https://site.financialmodelingprep.com/developer/docs
#'
#' @return price data
#' @export
get_fmp_fx <- function(pair = "EURUSD", frequency = "1min", from = "2022-03-02", to = from, apikey = read_file(".apikey")) {
  read_json(paste0("https://financialmodelingprep.com/api/v3/historical-chart/", frequency, "/", pair,
                   "?from=", from, "&to=", to,
                   "&apikey=", apikey),
            simplifyVector = T) |>
    as_tibble() |>
    mutate(date = ymd_hms(date))
}


