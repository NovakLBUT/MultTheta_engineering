import numpy as np
from beartype import beartype
from scipy.spatial.distance import cdist
import UQpy
from UQpy.surrogates import polynomial_chaos


class ThetaCriterionPCE:
    @beartype
    def __init__(self, surrogates: list[UQpy.surrogates.polynomial_chaos.PolynomialChaosExpansion]):
        self.surrogates = surrogates

    def run(
        self,
        existing_samples: np.ndarray,
        candidate_samples: np.ndarray,
        nsamples: int = 1,
        samples_weights=None,
        candidate_weights=None,
        enable_criterium: bool = False,
    ):

        pces = self.surrogates

        nsimexisting, nvar = existing_samples.shape
        nsimcandidate, _ = candidate_samples.shape

        if samples_weights is None:
            samples_weights = np.ones(nsimexisting)

        if candidate_weights is None:
            candidate_weights = np.ones(nsimcandidate)

        pos = []

        for _ in range(nsamples):

            S = polynomial_chaos.Polynomials.standardize_sample(
                existing_samples,
                pces[0].polynomial_basis.distributions
            )

            S_candidate = polynomial_chaos.Polynomials.standardize_sample(
                candidate_samples,
                pces[0].polynomial_basis.distributions
            )

            lengths = cdist(S_candidate, S)
            nn_idx = np.argmin(lengths, axis=1)
            l = np.nanmin(lengths, axis=1)

            closest_x = existing_samples[nn_idx]
            closest_w = samples_weights[nn_idx]

            sigma_c = []
            sigma_s = []

            for p in pces:
                sigma_c.append(
                    self._local_variance(
                        coordinates=candidate_samples,
                        pce=p,
                        weight=candidate_weights
                    )
                )

                sigma_s.append(
                    self._local_variance(
                        coordinates=closest_x,
                        pce=p,
                        weight=closest_w
                    )
                )

            SigmaC = np.vstack(sigma_c)
            SigmaS = np.vstack(sigma_s)

            maxC = np.maximum(SigmaC.max(axis=1, keepdims=True), 1e-15)
            maxS = np.maximum(SigmaS.max(axis=1, keepdims=True), 1e-15)

            vc = (SigmaC / maxC).sum(axis=0)
            vs = (SigmaS / maxS).sum(axis=0)

            criterium_v = np.sqrt(np.maximum(vc * vs, 0.0))
            criterium_l = np.maximum(l, 1e-15) ** nvar
            theta = criterium_v * criterium_l

            k = int(np.argmax(theta))
            pos.append(k)

            existing_samples = np.vstack([
                existing_samples,
                candidate_samples[[k], :]
            ])

            samples_weights = np.append(samples_weights, candidate_weights[k])

        return pos[0] if not enable_criterium and nsamples == 1 else pos

    @staticmethod
    def _local_variance(coordinates, pce, weight=1):
        """
        Compute local variance density for one PCE.

        The constant PCE coefficient is removed, so only non-constant
        polynomial terms contribute to the local variance indicator.
        """

        beta = np.asarray(pce.coefficients)

        if beta.ndim == 1:
            beta_nc = beta.copy()
            beta_nc[0] = 0.0
        else:
            beta_nc = beta.copy()
            beta_nc[0, :] = 0.0

        Phi = pce.polynomial_basis.evaluate_basis(coordinates)

        if np.isscalar(weight):
            Phi_w = Phi * float(weight)
        else:
            Phi_w = Phi * np.asarray(weight)[:, None]

        Y = Phi_w @ beta_nc

        if Y.ndim == 1:
            var_local = Y ** 2

        else:
            var_local = np.sum(Y ** 2, axis=1)

        pdf = polynomial_chaos.Polynomials.standardize_pdf(
            coordinates,
            pce.polynomial_basis.distributions
        )

        return var_local * pdf