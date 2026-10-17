"""Exercise the production route function with stored synthetic graph fixtures."""

import subprocess


def test_navigation_graph_suite(project):
    result = subprocess.run(
        ["jac", "test", "tests/navigation_graph_tests.jac", "-v"],
        cwd=project, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, timeout=120,
    )
    print(result.stdout)
    assert result.returncode == 0, result.stdout
    assert "Ran 7 tests" in result.stdout, "Jac must execute all seven graph tests"
