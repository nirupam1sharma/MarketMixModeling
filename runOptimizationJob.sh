#!/bin/sh -e

RSERVER_PATH=$(dirname "$0")
cd $RSERVER_PATH
Rscript ./src/optimization/OptimizationWrapper.R $1
