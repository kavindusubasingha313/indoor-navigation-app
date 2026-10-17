import from services.naviJacService { NaviJacMap, NaviJacRole, get_public_maps, create_public_map }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from .components.NaviJacHome { NaviJacHome }


def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<NaviJacHome />} />
        </Routes>
    </Router>;
}
