import from services.naviJacService { NaviJacMap, NaviJacRole, get_public_maps, create_public_map }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from services.naviJacService { NaviJacMap, NaviJacRole, NaviJacFloor, NaviJacRoom, NaviJacGeometry, get_public_maps, create_public_map, upload_floor_plan, seed_sumanadasa_floor, get_floor_editor_data, save_floor_editor_changes, calibrate_floor_scale }
import from components.NaviJacHome { NaviJacHome }
import from components.NaviJacFloorEditor { NaviJacFloorEditor }


def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<NaviJacHome />} />
            <Route path="/maps/sumanadasa/first-floor/edit" element={<NaviJacFloorEditor />} />
        </Routes>
    </Router>;
}
