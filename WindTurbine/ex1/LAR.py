import numpy as np
import copy
import logging
import matplotlib.pyplot as plt
import h5py

from tqdm import tqdm
from beartype import beartype
from scipy.spatial.distance import cdist

import UQpy
from UQpy.distributions import Normal
from UQpy.surrogates import polynomial_chaos
from UQpy.surrogates.polynomial_chaos import PolynomialChaosExpansion
from UQpy.surrogates.polynomial_chaos.regressions import LeastSquareRegression
from UQpy.surrogates.polynomial_chaos.polynomials.TotalDegreeBasis import TotalDegreeBasis

class LeastAngleRegression:
    @beartype
    def __init__(self, fit_intercept=False, verbose=False, n_nonzero_coefs=1000, normalize=False):
        self.fit_intercept = fit_intercept
        self.n_nonzero_coefs = n_nonzero_coefs
        self.normalize = normalize
        self.verbose = verbose
        self.logger = logging.getLogger(__name__)

    def run(self, x, y, design_matrix):
        from sklearn import linear_model as regresion

        reg = regresion.Lars(
            fit_intercept=self.fit_intercept,
            verbose=self.verbose,
            n_nonzero_coefs=self.n_nonzero_coefs
        )
        reg.fit(design_matrix, y)

        c_ = reg.coef_
        self.Beta_path = reg.coef_path_

        if c_.ndim == 1:
            c_ = c_.reshape(-1, 1)

        return c_, None, np.shape(c_)[1]

    @staticmethod
    def model_selection(pce_object, target_error=1, check_overfitting=True):
        pce = copy.deepcopy(pce_object)
        x = pce.experimental_design_input
        y = pce.experimental_design_output

        pce.regression_method = LeastAngleRegression()
        pce.fit(x, y)

        LarsBeta = pce.regression_method.Beta_path
        _, steps = LarsBeta.shape
        multindex = pce.multi_index_set

        pce.regression_method = LeastSquareRegression()

        larsbasis = []
        larsindex = []
        LarsError = []
        overfitting = False
        BestLarsError = 0.0
        step = 0

        if steps < 3:
            pce.polynomial_basis.polynomials_number = 1
            pce.polynomial_basis.polynomials = [pce_object.polynomial_basis.polynomials[0]]
            pce.multi_index_set = multindex[[0], :]
            pce.fit(x, y)
            return pce

        while (BestLarsError < target_error) and (step < steps - 2) and (not overfitting):
            mask = LarsBeta[:, step + 2] != 0
            mask[0] = True

            larsindex.append(multindex[mask, :])
            larsbasis.append(list(np.array(pce_object.polynomial_basis.polynomials)[mask]))

            pce.polynomial_basis.polynomials_number = len(larsbasis[step])
            pce.polynomial_basis.polynomials = larsbasis[step]
            pce.multi_index_set = larsindex[step]
            pce.fit(x, y)

            err = float(1 - pce.leaveoneout_error())
            LarsError.append(err)

            if step == 0 or err > BestLarsError:
                BestLarsMultindex = larsindex[step]
                BestLarsBasis = larsbasis[step]
                BestLarsError = err

            if (step > 3) and check_overfitting:
                if (
                    (BestLarsError > 0.6)
                    and (err < LarsError[step - 1])
                    and (err < LarsError[step - 2])
                    and (err < LarsError[step - 3])
                ):
                    overfitting = True

            step += 1

        pce.polynomial_basis.polynomials_number = len(BestLarsBasis)
        pce.polynomial_basis.polynomials = BestLarsBasis
        pce.multi_index_set = BestLarsMultindex
        pce.fit(x, y)

        return pce