import from .ui.button { Button }

def:pub NaviJacThemeToggle() -> JsxElement {
    has mode: str = "system";

    def apply_mode(next_mode: str) {
        mode = next_mode;
        localStorage.setItem("navijac-theme", next_mode);
        media_query: any = window.matchMedia("(prefers-color-scheme: dark)");
        system_prefers_dark = media_query.matches;
        dark_mode = next_mode == "dark" or (next_mode == "system" and system_prefers_dark);
        if dark_mode { document.documentElement.classList.add("dark"); }
        else { document.documentElement.classList.remove("dark"); }
    }

    async can with entry {
        stored_mode = localStorage.getItem("navijac-theme") or "system";
        apply_mode(stored_mode);
    }

    return <div className="flex items-center gap-1 rounded-lg border bg-card p-1" role="group" aria-label="Color theme">
        <Button size="sm" variant={"secondary" if mode == "light" else "ghost"} onClick={lambda { apply_mode("light"); }}>Light</Button>
        <Button size="sm" variant={"secondary" if mode == "dark" else "ghost"} onClick={lambda { apply_mode("dark"); }}>Dark</Button>
        <Button size="sm" variant={"secondary" if mode == "system" else "ghost"} onClick={lambda { apply_mode("system"); }}>System</Button>
    </div>;
}
