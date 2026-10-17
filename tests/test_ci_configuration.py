"""Guard against weakening existing main-branch protections when enabling CI."""

import importlib.util
from pathlib import Path


def test_review_only_protection_retains_existing_restrictions():
    path = Path(__file__).resolve().parents[1] / "ci/configure_branch_protection.py"
    spec = importlib.util.spec_from_file_location("protection", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    current = {
        "required_status_checks": None,
        "required_linear_history": {"enabled": True},
        "required_conversation_resolution": {"enabled": True},
        "allow_force_pushes": {"enabled": False},
        "restrictions": {"users": [{"login": "owner"}], "teams": [{"slug": "maintainers"}], "apps": []},
        "required_pull_request_reviews": {
            "required_approving_review_count": 2,
            "dismiss_stale_reviews": True,
            "require_code_owner_reviews": True,
            "require_last_push_approval": True,
            "dismissal_restrictions": {"users": [], "teams": [{"slug": "reviewers"}]},
        },
    }
    gate = {"strict": True, "checks": [{"context": "Required CI", "app_id": 15368}]}
    result = module.protection_payload(current, gate)
    assert result["required_status_checks"] == gate
    assert result["enforce_admins"] is True
    assert result["required_linear_history"] is True
    assert result["required_conversation_resolution"] is True
    assert result["allow_force_pushes"] is False
    assert result["restrictions"] == {"users": ["owner"], "teams": ["maintainers"], "apps": []}
    reviews = result["required_pull_request_reviews"]
    assert reviews["required_approving_review_count"] == 2
    assert reviews["require_code_owner_reviews"] is True
    assert reviews["dismiss_stale_reviews"] is True
    assert reviews["require_last_push_approval"] is True
    assert reviews["dismissal_restrictions"]["teams"] == ["reviewers"]
