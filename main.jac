import from services.naviJacService { NaviJacMap, NaviJacRole, get_public_maps, create_public_map }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from .services.naviJacService { NaviJacMap, NaviJacRole, get_public_maps, create_public_map, upload_floor_plan }
import from .components.NaviJacHome { NaviJacHome }


def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<NaviJacHome />} />
        </Routes>
    </Router>;
}
