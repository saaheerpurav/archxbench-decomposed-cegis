from __future__ import annotations

import json
import math
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from cegis.tdes.fpga.autonomous import golden_compare
from cegis.tdes.fpga.autonomous import run_aaai


def _write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


class StrictValueComparisonTests(unittest.TestCase):
    def test_ordinary_integers_are_not_reinterpreted_as_float_words(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            [10, 20], [0, 0], mode="integer"
        )
        self.assertEqual((passes, total), (0, 2))
        self.assertIn("FAIL", detail)

    def test_integer_mode_preserves_plus_or_minus_one_contract(self) -> None:
        passes, total, _ = golden_compare.compare_values(
            [10, 20, 30], [9, 21, 30], mode="integer"
        )
        self.assertEqual((passes, total), (3, 3))

    def test_extra_output_invalidates_otherwise_exact_prefix(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            [1, 2, 3], [1, 2, 3, 4], mode="integer"
        )
        self.assertLess(passes, total)
        self.assertIn("extra DUT", detail)

    def test_missing_output_invalidates_result(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            [1, 2, 3], [1, 2], mode="integer"
        )
        self.assertEqual((passes, total), (2, 3))
        self.assertIn("missing 1", detail)

    def test_non_finite_numeric_sample_is_rejected(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            [0], [math.nan], mode="integer"
        )
        self.assertEqual((passes, total), (0, 1))
        self.assertIn("not an integer sample", detail)

    def test_non_finite_fp32_word_is_rejected(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            ["0x00000000"], ["0x7fc00000"], mode="fp32"
        )
        self.assertEqual((passes, total), (0, 1))
        self.assertIn("non-finite FP32", detail)

    def test_c_object_schema_is_explicitly_unwrapped(self) -> None:
        passes, total, _ = golden_compare.compare_values(
            {"C": [[1, 2], [3, 4]]},
            {"C": [1, 2, 3, 4]},
            mode="integer",
        )
        self.assertEqual((passes, total), (4, 4))

    def test_quantized_matmul_bit_patterns_use_integer_distance(self) -> None:
        # The repaired QGEMM contract normalizes both sides to unsigned FP32
        # bit-pattern integers and explicitly compares their integer distance.
        passes, total, _ = golden_compare.compare_values(
            {"C": [0x3F800000, 0x40000000]},
            {"C": [0x3F800001, 0x40000000]},
            mode="integer",
        )
        self.assertEqual((passes, total), (2, 2))

    def test_unresolved_fft_schema_is_rejected_instead_of_guessed(self) -> None:
        passes, total, detail = golden_compare.compare_values(
            {"real_out": [1.0], "imag_out": [0.0]},
            [{"real": 1, "imag": 0}],
            mode="integer",
        )
        self.assertEqual((passes, total), (0, 1))
        self.assertIn("ambiguous object schema", detail)


class OutputFileContractTests(unittest.TestCase):
    def test_dct_and_idct_files_are_both_required_and_aggregated(self) -> None:
        with tempfile.TemporaryDirectory() as data_tmp, tempfile.TemporaryDirectory() as work_tmp:
            data = Path(data_tmp)
            work = Path(work_tmp)
            _write_json(data / "outputs" / "golden_dct.json", [1, 2])
            _write_json(data / "outputs" / "golden_idct.json", [3, 4])
            _write_json(work / "outputs" / "dut_dct.json", [1, 2])
            _write_json(work / "outputs" / "dut_idct.json", [3, 4])

            passes, total, detail = golden_compare.compare_output_files(data, work)

        self.assertEqual((passes, total), (4, 4))
        self.assertIn("DCT", detail)
        self.assertIn("IDCT", detail)

    def test_dct_missing_second_output_cannot_pass(self) -> None:
        with tempfile.TemporaryDirectory() as data_tmp, tempfile.TemporaryDirectory() as work_tmp:
            data = Path(data_tmp)
            work = Path(work_tmp)
            _write_json(data / "outputs" / "golden_dct.json", [1, 2])
            _write_json(data / "outputs" / "golden_idct.json", [3, 4])
            _write_json(work / "outputs" / "dut_dct.json", [1, 2])

            passes, total, detail = golden_compare.compare_output_files(data, work)

        self.assertEqual((passes, total), (2, 4))
        self.assertIn("IDCT: DUT output file not written", detail)

    def test_quantized_matmul_file_dispatch_stays_integer_not_fp32(self) -> None:
        with tempfile.TemporaryDirectory() as root_tmp, tempfile.TemporaryDirectory() as work_tmp:
            data = Path(root_tmp) / "quantized_matmul"
            work = Path(work_tmp)
            # As FP32 these represent 1.0 and 0.0 and would pass the FIR's
            # deliberately broad +/-1.0 tolerance. QGEMM instead compares its
            # normalized bit-pattern integers, so they must fail.
            _write_json(
                data / "outputs" / "golden_output.json", {"C": [0x3F800000]}
            )
            _write_json(work / "outputs" / "dut_output.json", {"C": [0]})

            passes, total, detail = golden_compare.compare_output_files(data, work)

        self.assertEqual((passes, total), (0, 1))
        self.assertIn("FAIL", detail)

    def test_harris_file_dispatch_is_exact_for_binary_corner_mask(self) -> None:
        with tempfile.TemporaryDirectory() as root_tmp, tempfile.TemporaryDirectory() as work_tmp:
            data = Path(root_tmp) / "harris_corner_detection"
            work = Path(work_tmp)
            _write_json(data / "outputs" / "golden_output.json", [0])
            _write_json(work / "outputs" / "dut_output.json", [1])

            passes, total, detail = golden_compare.compare_output_files(data, work)

        # Integer +/-1 tolerance would incorrectly accept this classification
        # error, so Harris must use exact comparison.
        self.assertEqual((passes, total), (0, 1))
        self.assertIn("FAIL", detail)

    def test_explicit_fp32_contract_can_tighten_tolerance(self) -> None:
        with tempfile.TemporaryDirectory() as root_tmp, tempfile.TemporaryDirectory() as work_tmp:
            data = Path(root_tmp) / "fp_low_pass_fir"
            work = Path(work_tmp)
            _write_json(
                data / "golden_contract.json",
                {"mode": "fp32", "absolute_tolerance": 1e-6},
            )
            _write_json(data / "outputs" / "golden_output.json", ["0x3f800000"])
            _write_json(work / "outputs" / "dut_output.json", ["0x3f800011"])

            passes, total, detail = golden_compare.compare_output_files(data, work)

        self.assertEqual((passes, total), (0, 1))
        self.assertIn("FAIL", detail)


class SimulationSafetyTests(unittest.TestCase):
    def _fixture_with_stale_dut(self, root: Path) -> Path:
        data = root / "conv1d"
        _write_json(data / "outputs" / "golden_output.json", [10])
        _write_json(data / "outputs" / "dut_output.json", [10])
        return data

    def test_simulation_cannot_reuse_copied_stale_dut_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            data = self._fixture_with_stale_dut(Path(tmpdir))
            with (
                mock.patch.object(run_aaai, "find_tool", side_effect=lambda names: names[0]),
                mock.patch.object(
                    run_aaai,
                    "_run",
                    side_effect=[(0, "", "", False), (0, "", "", False)],
                ),
            ):
                passes, total, detail = run_aaai._simulate_golden(
                    {"dut": "module dut; endmodule"},
                    "module tb; initial $finish; endmodule",
                    str(data),
                )

        self.assertEqual((passes, total), (0, 1))
        self.assertIn("DUT output file not written", detail)

    def test_nonzero_compile_return_code_stops_before_simulation(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            data = self._fixture_with_stale_dut(Path(tmpdir))
            run_mock = mock.Mock(return_value=(2, "", "compile failed", False))
            with (
                mock.patch.object(run_aaai, "find_tool", return_value="iverilog"),
                mock.patch.object(run_aaai, "_run", run_mock),
            ):
                passes, total, detail = run_aaai._simulate_golden(
                    {"dut": "module dut; endmodule"}, "module tb; endmodule", str(data)
                )

        self.assertEqual((passes, total), (0, 0))
        self.assertIn("compile error", detail)
        run_mock.assert_called_once()

    def test_nonzero_simulation_return_code_is_not_compared(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            data = self._fixture_with_stale_dut(Path(tmpdir))
            with (
                mock.patch.object(run_aaai, "find_tool", side_effect=lambda names: names[0]),
                mock.patch.object(
                    run_aaai,
                    "_run",
                    side_effect=[
                        (0, "", "", False),
                        (3, "", "simulation failed", False),
                    ],
                ),
            ):
                passes, total, detail = run_aaai._simulate_golden(
                    {"dut": "module dut; endmodule"}, "module tb; endmodule", str(data)
                )

        self.assertEqual((passes, total), (0, 0))
        self.assertIn("simulation error", detail)


class C4tlGoldenScoringTests(unittest.TestCase):
    def test_golden_score_is_used_when_native_testbench_has_zero_tests(self) -> None:
        simulated = SimpleNamespace(compiled=True, stdout="simulation produced no verdict tokens")
        modules = {"dut": "module dut; endmodule"}
        with (
            mock.patch.object(run_aaai, "simulate", return_value=simulated),
            mock.patch.object(
                run_aaai,
                "_simulate_golden",
                return_value=(7, 8, "one strict golden mismatch"),
            ) as golden_mock,
        ):
            score = run_aaai._golden_score_modules(
                modules,
                "module tb; endmodule",
                "path/to/file_output_fixture",
            )

        self.assertEqual(score, (7, 8))
        golden_mock.assert_called_once_with(
            modules,
            "module tb; endmodule",
            "path/to/file_output_fixture",
        )


if __name__ == "__main__":
    unittest.main()
