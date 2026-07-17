from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from scripts import build_repaired_contract_matrix
from scripts import build_run_matrix
from scripts import build_noref_ablation_matrix


def _write_result(path: Path, **overrides: object) -> None:
    data: dict[str, object] = {
        "design": "conv1d",
        "condition": "C2g",
        "model": "gpt-5.5",
        "seed": 42,
        "best_passes": 16,
        "total_tests": 16,
        "golden_correct": 16,
        "golden_total": 16,
        "solved": True,
    }
    data.update(overrides)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding="utf-8")


def _write_audit(result_path: Path, **overrides: object) -> None:
    data: dict[str, object] = {
        "strict_correct": 0,
        "strict_total": 16,
        "strict_solved": False,
        "verifier_version": "strict-v1",
    }
    data.update(overrides)
    result_path.with_name("strict_audit.json").write_text(
        json.dumps(data), encoding="utf-8"
    )


class OriginalMatrixProvenanceTests(unittest.TestCase):
    def test_repaired_path_detection_covers_prefix_and_suffix_conventions(self) -> None:
        self.assertTrue(
            build_run_matrix.is_repaired_contract_path(
                ("artifacts", "raw_runs", "repaired_contracts_20260716")
            )
        )
        self.assertTrue(
            build_run_matrix.is_repaired_contract_path(
                ("artifacts", "raw_runs", "c2g_artifact_collection_20260709_repaired")
            )
        )
        self.assertTrue(
            build_run_matrix.is_repaired_contract_path(
                (
                    "artifacts",
                    "raw_runs",
                    "acceptance_repaired_codex_gpt55_20260716",
                )
            )
        )
        self.assertFalse(
            build_run_matrix.is_repaired_contract_path(
                ("artifacts", "raw_runs", "original_contracts_20260716")
            )
        )

    def test_original_collector_excludes_every_repaired_root_style(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            _write_result(
                artifacts / "raw_runs" / "original_run" / "conv1d" / "result.json",
                seed=42,
            )
            _write_result(
                artifacts
                / "raw_runs"
                / "repaired_contracts_demo"
                / "conv1d"
                / "result.json",
                seed=123,
            )
            _write_result(
                artifacts
                / "raw_runs"
                / "c2g_artifact_collection_repaired"
                / "conv1d"
                / "result.json",
                seed=456,
            )
            _write_result(
                artifacts
                / "raw_runs"
                / "acceptance_repaired_codex_gpt55_20260716"
                / "conv1d"
                / "result.json",
                seed=789,
            )

            with (
                mock.patch.object(build_run_matrix, "ROOT", root),
                mock.patch.object(build_run_matrix, "ARTIFACTS", artifacts),
                mock.patch.object(
                    build_run_matrix,
                    "official_designs",
                    return_value=[("L5", "conv1d")],
                ),
            ):
                rows = build_run_matrix.collect_results()

            self.assertEqual([row["seed"] for row in rows], ["42"])

    def test_strict_audit_failure_overrides_stale_claim_and_canonicalization(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            unaudited = (
                artifacts / "raw_runs" / "attempt_a" / "conv1d" / "result.json"
            )
            audited = (
                artifacts / "raw_runs" / "attempt_b" / "conv1d" / "result.json"
            )
            _write_result(unaudited)
            _write_result(audited)
            _write_audit(audited)

            with (
                mock.patch.object(build_run_matrix, "ROOT", root),
                mock.patch.object(build_run_matrix, "ARTIFACTS", artifacts),
                mock.patch.object(
                    build_run_matrix,
                    "official_designs",
                    return_value=[("L5", "conv1d")],
                ),
            ):
                rows = build_run_matrix.collect_results()

            self.assertEqual(len(rows), 1)
            self.assertFalse(rows[0]["strict_clean"])
            self.assertEqual(rows[0]["golden"], "0/16")
            self.assertEqual(rows[0]["verification_source"], "strict_audit")
            self.assertEqual(rows[0]["verifier_version"], "strict-v1")


class RepairedMatrixProvenanceTests(unittest.TestCase):
    def test_repaired_collector_accepts_acceptance_repaired_run(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            _write_result(
                artifacts
                / "raw_runs"
                / "acceptance_repaired_codex_gpt55_20260716"
                / "conv1d"
                / "result.json"
            )

            with (
                mock.patch.object(build_repaired_contract_matrix, "ROOT", root),
                mock.patch.object(
                    build_repaired_contract_matrix, "ARTIFACTS", artifacts
                ),
            ):
                rows = build_repaired_contract_matrix.collect()

            self.assertEqual(len(rows), 1)
            self.assertEqual(
                rows[0]["contract_run"],
                "acceptance_repaired_codex_gpt55_20260716",
            )

    def test_repaired_collector_accepts_trailing_suffix_run(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            _write_result(
                artifacts
                / "raw_runs"
                / "c2g_artifact_collection_repaired"
                / "conv1d"
                / "result.json"
            )

            with (
                mock.patch.object(build_repaired_contract_matrix, "ROOT", root),
                mock.patch.object(
                    build_repaired_contract_matrix, "ARTIFACTS", artifacts
                ),
            ):
                rows = build_repaired_contract_matrix.collect()

            self.assertEqual(len(rows), 1)
            self.assertEqual(
                rows[0]["contract_run"], "c2g_artifact_collection_repaired"
            )

    def test_repaired_collector_prefers_strict_audit_score(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            result = (
                artifacts
                / "raw_runs"
                / "demo_repaired"
                / "conv1d"
                / "result.json"
            )
            _write_result(result)
            _write_audit(result, strict_correct=7, strict_total=16)

            with (
                mock.patch.object(build_repaired_contract_matrix, "ROOT", root),
                mock.patch.object(
                    build_repaired_contract_matrix, "ARTIFACTS", artifacts
                ),
            ):
                rows = build_repaired_contract_matrix.collect()

            self.assertEqual(len(rows), 1)
            self.assertFalse(rows[0]["strict_clean"])
            self.assertEqual(rows[0]["golden"], "7/16")
            self.assertEqual(rows[0]["verification_source"], "strict_audit")


class NoRefAblationMatrixTests(unittest.TestCase):
    def test_noref_is_separate_from_main_and_repaired_collectors(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            artifacts = root / "artifacts"
            result = (
                artifacts
                / "raw_runs"
                / "acceptance_original_demo"
                / "conv1d"
                / "C4tl-noRef"
                / "42"
                / "result.json"
            )
            _write_result(result, condition="C4tl-noRef")
            _write_audit(
                result,
                strict_correct=16,
                strict_total=16,
                strict_solved=True,
            )

            with (
                mock.patch.object(build_run_matrix, "ROOT", root),
                mock.patch.object(build_run_matrix, "ARTIFACTS", artifacts),
                mock.patch.object(
                    build_run_matrix,
                    "official_designs",
                    return_value=[("L5", "conv1d")],
                ),
                mock.patch.object(build_repaired_contract_matrix, "ROOT", root),
                mock.patch.object(
                    build_repaired_contract_matrix, "ARTIFACTS", artifacts
                ),
                mock.patch.object(build_noref_ablation_matrix, "ROOT", root),
                mock.patch.object(
                    build_noref_ablation_matrix, "ARTIFACTS", artifacts
                ),
            ):
                original_rows = build_run_matrix.collect_results()
                repaired_rows = build_repaired_contract_matrix.collect()
                noref_rows = build_noref_ablation_matrix.collect()

            self.assertEqual(original_rows, [])
            self.assertEqual(repaired_rows, [])
            self.assertEqual(len(noref_rows), 1)
            self.assertTrue(noref_rows[0]["strict_clean"])
            self.assertEqual(noref_rows[0]["condition"], "C4tl-noRef")


if __name__ == "__main__":
    unittest.main()
