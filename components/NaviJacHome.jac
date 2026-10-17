import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }
import from .ui.input { Input }
import from "@jac/runtime" { Link }
sv import from ..services.naviJacService { NaviJacMap, get_public_maps, create_public_map, upload_floor_plan }


def:pub NaviJacHome() -> JsxElement {
    has maps: list[NaviJacMap] = [],
        map_name: str = "",
        map_description: str = "",
        feedback: str = "",
        loading: bool = True,
        uploading_map_id: str = "";

    async can with entry {
        maps = await get_public_maps();
        loading = False;
    }

    def handle_name(e: ChangeEvent) { map_name = e.target.value; }
    def handle_description(e: ChangeEvent) { map_description = e.target.value; }

    async def handle_create -> None {
        feedback = "";
        if len(map_name.strip()) == 0 {
            feedback = "Enter a building name to continue.";
        } else {
            created = await create_public_map(map_name, map_description);
            if created is None {
                feedback = "A building name is required.";
            } else {
                maps = maps + [created];
                map_name = "";
                map_description = "";
                feedback = "Public building added. You can now upload its floor plan.";
            }
        }
    }

    async def handle_plan_change(e: ChangeEvent) {
        file = e.target.files[0];
        if not file {
            return;
        }
        mime_type: str = file.type;
        if mime_type != "image/png" and mime_type != "image/jpeg" {
            feedback = "Choose a PNG or JPG floor-plan image.";
            return;
        }
        if file.size > 5000000 {
            feedback = "The image must be 5 MB or smaller.";
            return;
        }
        reader: any = new(FileReader);
        reader.onload = lambda (_event: Event) {
            raw_result = reader.result as str;
            split_data = raw_result.split(",");
            if len(split_data) < 2 {
                feedback = "The selected image could not be read.";
                return;
            }
            async def save_plan -> None {
                updated = await upload_floor_plan(uploading_map_id, split_data[1], mime_type);
                if updated is None {
                    feedback = "The floor plan could not be saved. Please try again.";
                } else {
                    maps = [updated if jid(item) == uploading_map_id else item for item in maps];
                    feedback = "Floor plan saved and ready to view.";
                }
                uploading_map_id = "";
            }
            save_plan();
        };
        uploading_map_id = e.target.dataset["mapid"] as str;
        feedback = "Reading floor-plan image…";
        reader.readAsDataURL(file);
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background">
            <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between gap-4 px-5 sm:px-8">
                <Link to="/" className="flex items-center gap-3 text-foreground no-underline">
                    <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-bold">N</span>
                    <span className="text-lg font-semibold tracking-tight">NaviJac</span>
                </Link>
                <Badge variant="secondary">Public map directory</Badge>
            </div>
        </header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-8 px-5 py-8 sm:px-8 sm:py-12">
            <section className="grid gap-6 rounded-2xl border bg-card p-6 shadow-sm md:grid-cols-[1fr_auto] md:items-end md:p-9">
                <div className="flex max-w-3xl flex-col gap-4">
                    <Badge variant="outline" className="w-fit">Indoor navigation foundation</Badge>
                    <h1 className="text-balance text-3xl font-semibold leading-tight tracking-tight sm:text-4xl">Find your way through the building.</h1>
                    <p className="max-w-2xl text-base leading-relaxed text-muted-foreground">Start with one floor plan. Add verified walkable routes and more floors as the map develops.</p>
                </div>
                <div className="flex flex-col gap-1 rounded-xl bg-muted/60 p-4 md:min-w-52">
                    <span className="text-sm font-medium">Open to public visitors</span>
                    <span className="text-sm text-muted-foreground">Browse the building directory and view uploaded floor plans.</span>
                </div>
            </section>

            <section className="flex flex-col gap-5">
                <div className="flex flex-wrap items-end justify-between gap-4">
                    <div className="flex flex-col gap-1">
                        <h2 className="text-2xl font-semibold tracking-tight">Public buildings</h2>
                        <p className="text-sm text-muted-foreground">Browse the current single-floor experimental maps.</p>
                    </div>
                    <span className="text-sm text-muted-foreground">{str(len(maps))} public maps</span>
                </div>
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Building directory</CardTitle>
                        <CardDescription>Floor plans appear here after a map creator uploads them.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        {if loading {
                            <div className="rounded-xl border border-dashed bg-muted/30 p-8 text-center text-sm text-muted-foreground">Loading public maps…</div>
                            skip;
                        }}
                        {if len(maps) == 0 {
                            <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed bg-muted/30 px-5 py-12 text-center">
                                <span className="text-base font-semibold">No public maps yet</span>
                                <span className="max-w-md text-sm text-muted-foreground">Create a building record, then attach its floor plan to make it available here.</span>
                            </div>
                            skip;
                        }}
                        <div className="grid gap-5 md:grid-cols-2">
                            {for building in maps {
                                <article key={jid(building)} className="flex min-w-0 flex-col gap-4 rounded-xl border bg-background p-4 shadow-sm">
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="flex flex-col gap-1">
                                            <h3 className="text-lg font-semibold">{building.name}</h3>
                                            <p className="text-sm text-muted-foreground">{building.description if len(building.description) > 0 else "Single-floor building plan"}</p>
                                        </div>
                                        <Badge variant="secondary">Public</Badge>
                                    </div>
                                    {if building.floor_plan_data {
                                        <div className="overflow-hidden rounded-lg border bg-muted/30">
                                            <img src={"data:" + building.floor_plan_type + ";base64," + building.floor_plan_data} alt={"Floor plan for " + building.name} className="max-h-[28rem] w-full object-contain" />
                                        </div>
                                    } else {
                                        <div className="flex min-h-48 flex-col items-center justify-center gap-2 rounded-lg border border-dashed bg-muted/30 p-6 text-center">
                                            <span className="font-medium">Floor plan not uploaded</span>
                                            <span className="text-sm text-muted-foreground">A creator can attach a PNG or JPG map.</span>
                                        </div>
                                    }}
                                    <div className="border-t pt-3 text-sm text-muted-foreground">Floor 1 · route locations will be added after verification</div>
                                </article>
                            }}
                        </div>
                    </CardContent>
                </Card>
            </section>

            <section className="grid gap-5 lg:grid-cols-[1fr_1fr]">
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Create a building map</CardTitle>
                        <CardDescription>Add a public building record, then upload its single-floor plan.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form className="flex flex-col gap-4" onSubmit={lambda (e: FormEvent) { e.preventDefault(); handle_create(); }}>
                            <label className="flex flex-col gap-2 text-sm font-medium">Building name
                                <Input placeholder="For example, Engineering Building" value={map_name} onChange={handle_name} />
                            </label>
                            <label className="flex flex-col gap-2 text-sm font-medium">Description <span className="font-normal text-muted-foreground">Optional</span>
                                <textarea className="min-h-24 resize-y rounded-md border bg-background px-3 py-2 font-normal shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-ring" placeholder="A short public description" value={map_description} onChange={handle_description} />
                            </label>
                            <Button type="submit" className="w-full sm:w-fit">Create public building</Button>
                        </form>
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Upload a floor plan</CardTitle>
                        <CardDescription>Select a building below, then upload its PNG or JPG plan. Maximum file size is 5 MB.</CardDescription>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-4">
                        {if len(maps) == 0 {
                            <p className="rounded-lg border border-dashed bg-muted/30 p-5 text-sm text-muted-foreground">Create a public building first to enable its floor-plan upload.</p>
                            skip;
                        }}
                        {for building in maps {
                            <label key={jid(building)} className="flex flex-col gap-2 rounded-lg border bg-background p-4 text-sm font-medium">
                                {"Upload plan for " + building.name}
                                <input type="file" accept="image/png,image/jpeg" data-mapid={jid(building)} onChange={handle_plan_change} className="block w-full cursor-pointer rounded-md border bg-background p-2 text-sm file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-2 file:text-sm file:font-medium file:text-primary-foreground" />
                            </label>
                        }}
                        {feedback and <p role="status" className="rounded-lg bg-muted/60 p-3 text-sm text-muted-foreground">{feedback}</p>}
                    </CardContent>
                </Card>
            </section>
            <footer className="border-t pt-5 text-xs text-muted-foreground">NaviJac experimental map · Route geometry and directions are not yet defined.</footer>
        </main>
    </div>;
}
