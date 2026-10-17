import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from services.naviJacService { NaviJacMap, NaviJacRole, NaviJacFloor, NaviJacRoom, NaviJacGeometry, NaviJacCheckpoint, NaviJacWaypoint, NaviJacConnection, NaviJacTimetableEntry, get_public_maps, get_featured_demo, get_public_room_profile, get_owned_maps, create_owned_map, update_owned_map, publish_owned_map, upload_floor_plan, seed_sumanadasa_floor, get_floor_editor_data, save_floor_editor_changes, calibrate_floor_scale, save_checkpoint_placement, save_corridor_waypoint, save_connection_edge, verify_connection_edge, get_graph_validation_summary, find_verified_route, get_my_timetable, create_timetable_entry, preview_timetable_csv, import_timetable_csv, bulk_approve_experimental_edges }
import from .components.NaviJacHome { NaviJacHome }
import from .components.NaviJacFloorEditor { NaviJacFloorEditor }
import from .components.NaviJacRouteFinder { NaviJacRouteFinder }
import from .components.NaviJacCreator { NaviJacCreator }
import from .components.NaviJacTimetable { NaviJacTimetable }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<NaviJacHome />} />
            <Route path="/maps/sumanadasa/first-floor/edit" element={<NaviJacFloorEditor />} />
            <Route path="/maps/sumanadasa/first-floor/route" element={<NaviJacRouteFinder />} />
            <Route path="/creator" element={<NaviJacCreator />} />
            <Route path="/timetable" element={<NaviJacTimetable />} />
        </Routes>
    </Router>;
}
