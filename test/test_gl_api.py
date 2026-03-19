"""
Unit tests for the Ovarrior GL Prediction API
Author: Fathima Bushra Sahir Hussain (G21318993)

Tests the calculate_gl formula, GL classification thresholds, portion
scaling logic, and multi-food meal aggregation.

Note on the formula: The Lee et al. (2021) mixed-meal formula has an
intercept of 19.27, meaning it is calibrated for complete mixed meals
rather than individual foods in isolation. As a result, individual food
items alone will frequently score in the Moderate or High range. This is
expected behaviour and is documented as a known limitation.

Run with: python -m pytest test_gl_api.py -v
     or:  python test_gl_api.py
"""

import unittest


def calculate_gl(carbs: float, fat: float, protein: float, fiber: float) -> float:
    """
    Lee et al. (2021) mixed-meal GL formula.
    GL = 19.27 + (0.39 × Carbs) - (0.21 × Fat) - (0.01 × Protein²) - (0.01 × Fiber²)
    Validated: R² = 0.73, p < 0.001 (70 meals, 64 participants).
    """
    return (19.27
            + (0.39 * carbs)
            - (0.21 * fat)
            - (0.01 * protein ** 2)
            - (0.01 * fiber ** 2))


def classify_gl(gl: float) -> str:
    if gl < 10:
        return "Low"
    elif gl < 20:
        return "Moderate"
    else:
        return "High"


def scale_macros(macros_per_100g: dict, grams: float) -> dict:
    """Scale macronutrient values from per-100g to actual portion size."""
    factor = grams / 100.0
    return {k: v * factor for k, v in macros_per_100g.items()}


# ── GL Formula Tests ───────────────────────────────────────────────────────────

class TestGLFormula(unittest.TestCase):

    def test_zero_inputs_return_intercept(self):
        """Zero macros should return the formula intercept (19.27)."""
        result = calculate_gl(carbs=0, fat=0, protein=0, fiber=0)
        self.assertAlmostEqual(result, 19.27, places=2,
            msg=f"Zero input should return intercept 19.27, got {result:.2f}")

    def test_formula_accuracy_manual_calculation(self):
        """
        Manual cross-validation:
        carbs=50, fat=10, protein=20, fiber=5
        = 19.27 + 19.5 - 2.1 - 4.0 - 0.25 = 32.42
        """
        expected = 19.27 + (0.39*50) - (0.21*10) - (0.01*20**2) - (0.01*5**2)
        result   = calculate_gl(carbs=50, fat=10, protein=20, fiber=5)
        self.assertAlmostEqual(result, expected, places=2,
            msg=f"Formula mismatch: expected {expected:.2f}, got {result:.2f}")

    def test_high_fibre_lowers_gl(self):
        """Adding fibre to the same meal should reduce GL (squared suppression term)."""
        gl_low  = calculate_gl(carbs=40, fat=5, protein=10, fiber=2)
        gl_high = calculate_gl(carbs=40, fat=5, protein=10, fiber=20)
        self.assertLess(gl_high, gl_low,
            "High-fibre meal should have lower GL than low-fibre equivalent")

    def test_high_protein_lowers_gl(self):
        """Higher protein should reduce GL via the squared protein term."""
        gl_low  = calculate_gl(carbs=40, fat=5, protein=5,  fiber=5)
        gl_high = calculate_gl(carbs=40, fat=5, protein=40, fiber=5)
        self.assertLess(gl_high, gl_low,
            "High-protein meal should have lower GL than low-protein equivalent")

    def test_high_fat_lowers_gl(self):
        """Fat attenuates insulin response — higher fat should reduce GL."""
        gl_low  = calculate_gl(carbs=40, fat=1,  protein=10, fiber=5)
        gl_high = calculate_gl(carbs=40, fat=30, protein=10, fiber=5)
        self.assertLess(gl_high, gl_low,
            "High-fat meal should have lower GL than low-fat equivalent")

    def test_increasing_carbs_raises_gl(self):
        """More carbohydrates should increase GL, all else equal."""
        gl_low  = calculate_gl(carbs=10, fat=5, protein=10, fiber=5)
        gl_high = calculate_gl(carbs=80, fat=5, protein=10, fiber=5)
        self.assertGreater(gl_high, gl_low,
            "Higher carb meal should produce higher GL")

    def test_protein_dominated_meal_suppressed(self):
        """
        A protein-only meal (e.g. grilled chicken) should score low.
        Chicken 120g: carbs≈0, fat=3.6, protein=35, fiber=0
        Expected GL ≈ 6.26 (Low) — the only test case where a single
        food drops below 10 due to extreme protein suppression.
        """
        gl = calculate_gl(carbs=0, fat=3.6, protein=35, fiber=0)
        self.assertLess(gl, 10,
            f"Protein-only meal should be Low GL; got {gl:.2f}")

    def test_gl_positive_for_realistic_meal(self):
        """GL should be positive for a realistic high-fat, high-protein meal.\n        Note: extreme non-meal inputs (fat=50, protein=60) can go negative\n        due to the polynomial nature of the formula — a known limitation.\n        """
        gl = calculate_gl(carbs=30, fat=20, protein=40, fiber=15)  # realistic heavy meal
        self.assertGreaterEqual(gl, 0,
            f"GL should not be negative; got {gl:.2f}")

    def test_mixed_meal_rice_and_chicken(self):
        """
        Rice + chicken aggregated:
        Rice 150g: carbs=35.7, fat=0.3, protein=3.5, fiber=0.6
        Chicken 120g: carbs=0, fat=3.6, protein=35, fiber=0
        Protein suppression from chicken should significantly reduce GL vs rice alone.
        """
        gl_rice_only = calculate_gl(35.7, 0.3, 3.5, 0.6)
        gl_combined  = calculate_gl(35.7, 0.3+3.6, 3.5+35, 0.6+0)
        self.assertLess(gl_combined, gl_rice_only,
            "Adding chicken (high protein) to rice should lower GL")


# ── Classification Tests ───────────────────────────────────────────────────────

class TestGLClassification(unittest.TestCase):

    def test_below_10_is_low(self):
        self.assertEqual(classify_gl(5.0),  "Low")
        self.assertEqual(classify_gl(9.99), "Low")

    def test_10_to_19_is_moderate(self):
        self.assertEqual(classify_gl(10.0),  "Moderate")
        self.assertEqual(classify_gl(15.0),  "Moderate")
        self.assertEqual(classify_gl(19.99), "Moderate")

    def test_20_and_above_is_high(self):
        self.assertEqual(classify_gl(20.0), "High")
        self.assertEqual(classify_gl(35.0), "High")
        self.assertEqual(classify_gl(60.0), "High")

    def test_boundary_10_is_moderate_not_low(self):
        self.assertEqual(classify_gl(10.0), "Moderate",
            "Boundary value 10.0 should be Moderate, not Low")

    def test_boundary_20_is_high_not_moderate(self):
        self.assertEqual(classify_gl(20.0), "High",
            "Boundary value 20.0 should be High, not Moderate")


# ── Portion Scaling Tests ──────────────────────────────────────────────────────

class TestPortionScaling(unittest.TestCase):

    def test_100g_unchanged(self):
        macros = {'carbs': 30.0, 'fat': 6.0, 'protein': 8.0, 'fiber': 2.0}
        scaled = scale_macros(macros, grams=100)
        for key in macros:
            self.assertAlmostEqual(scaled[key], macros[key],
                msg=f"{key} should be unchanged at 100g")

    def test_half_portion(self):
        macros = {'carbs': 40.0, 'fat': 8.0, 'protein': 12.0, 'fiber': 4.0}
        scaled = scale_macros(macros, grams=50)
        self.assertAlmostEqual(scaled['carbs'],   20.0)
        self.assertAlmostEqual(scaled['fat'],       4.0)
        self.assertAlmostEqual(scaled['protein'],   6.0)
        self.assertAlmostEqual(scaled['fiber'],     2.0)

    def test_double_portion(self):
        macros = {'carbs': 20.0, 'fat': 5.0, 'protein': 10.0, 'fiber': 3.0}
        scaled = scale_macros(macros, grams=200)
        self.assertAlmostEqual(scaled['carbs'],   40.0)
        self.assertAlmostEqual(scaled['protein'], 20.0)

    def test_zero_grams_all_zero(self):
        macros = {'carbs': 30.0, 'fat': 6.0, 'protein': 8.0, 'fiber': 2.0}
        scaled = scale_macros(macros, grams=0)
        for key in macros:
            self.assertAlmostEqual(scaled[key], 0.0,
                msg=f"{key} should be 0 when grams=0")

    def test_non_standard_portion(self):
        """150g portion should scale proportionally from 100g base."""
        macros = {'carbs': 20.0, 'fat': 4.0, 'protein': 6.0, 'fiber': 2.0}
        scaled = scale_macros(macros, grams=150)
        self.assertAlmostEqual(scaled['carbs'], 30.0)
        self.assertAlmostEqual(scaled['fiber'],  3.0)


# ── Multi-Food Aggregation Tests ───────────────────────────────────────────────

class TestMealAggregation(unittest.TestCase):

    def test_adding_high_protein_food_reduces_meal_gl(self):
        """
        Adding a high-protein food to a carb-heavy base should reduce GL.
        This validates the multi-food meal aggregation logic.
        """
        gl_base    = calculate_gl(carbs=50, fat=2, protein=5, fiber=2)
        gl_with_protein = calculate_gl(carbs=50, fat=2+4, protein=5+30, fiber=2)
        self.assertLess(gl_with_protein, gl_base,
            "High-protein food addition should reduce meal GL")

    def test_adding_high_fibre_food_reduces_meal_gl(self):
        """Adding vegetables (high fibre) to a meal should reduce GL."""
        gl_base      = calculate_gl(carbs=45, fat=5, protein=10, fiber=2)
        gl_with_veg  = calculate_gl(carbs=45+5, fat=5+1, protein=10+2, fiber=2+12)
        self.assertLess(gl_with_veg, gl_base,
            "Adding high-fibre vegetables should reduce meal GL")

    def test_three_food_meal_gl_is_deterministic(self):
        """Same inputs should always produce the same GL output."""
        gl1 = calculate_gl(carbs=55, fat=12, protein=25, fiber=6)
        gl2 = calculate_gl(carbs=55, fat=12, protein=25, fiber=6)
        self.assertEqual(gl1, gl2, "GL calculation must be deterministic")


if __name__ == '__main__':
    unittest.main(verbosity=2)
    