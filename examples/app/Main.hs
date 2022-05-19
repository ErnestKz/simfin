{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main
  ( main
  ) where

import Control.Monad
import Data.Time.Calendar
import Data.Time.LocalTime
import Data.Maybe
import Data.Either
import qualified Data.Text as T
import Graphics.Rendering.Chart.Easy hiding (close)
import Graphics.Rendering.Chart.Backend.Diagrams

import SimFin.Free

day2020 :: Day
day2020 = fromGregorian 2020 01 01

to5pm :: Day -> LocalTime
to5pm = flip LocalTime $ dayFractionToTimeOfDay $ 17 / 24

toDataPoint :: PricesRow Double -> Maybe (LocalTime, Double)
toDataPoint row = do
  day <- date row
  pure (to5pm day, close row)

stonks :: [StockRef]
stonks = ["GOOG", "AAPL", "TWTR", "NFLX"]

getLineName :: PricesRow a -> String
getLineName PricesRow{ticker = t} = T.unpack $ t

type LineData = (String, [(LocalTime, Double)])

toLine :: [PricesRow Double] -> LineData
toLine pts@(x : xs) = (getLineName x, catMaybes $ toDataPoint <$> pts)

main :: IO ()
main = do
  ctx <- createDefaultContext

  pricesRes :: [ApiResult [PricesRow Double]] <- traverse (fetchPrices ctx) stonks
  let prices :: [LineData] = toLine <$> rights pricesRes

  toFile def "prices.svg" $ do
    layout_title .= "Price History"
    layout_background .= solidFillStyle (opaque white)
    layout_foreground .= opaque black
    layout_left_axis_visibility . axis_show_ticks .= False
    layout_x_axis . laxis_title .= "Date"
    layout_y_axis . laxis_title .= "Price ($)"
    forM_ prices $ \(name, pts) -> plot $ line name [pts]
  pure ()
