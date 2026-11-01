"""Scalable Vector Graphics (SVG) 2D Floor Plan Renderer per SP-AI-07, SP-AI-10, and Phase 2 Standards."""
import html
from typing import List, Optional
from backend.app.schemas.plot import OrientationEnum, PlotInput
from backend.app.schemas.response import (
    CirculationPathOutput,
    DoorOutput,
    MANDATORY_DISCLAIMER,
    RoomOutput,
    SpatialBreakdownOutput,
    WindowOutput,
)


class SVGFloorPlanRenderer:
    """Renders high-quality architectural 2D vector floor plans with structural walls, doors, windows, corridors, and disclaimer."""

    CATEGORY_COLORS = {
        "bedroom": {"fill": "#F5F3FF", "stroke": "#4F46E5", "text": "#312E81", "badge": "#EDE9FE"},
        "bathroom": {"fill": "#ECFEFF", "stroke": "#0891B2", "text": "#164E63", "badge": "#CFFAFE"},
        "kitchen": {"fill": "#FFFBEB", "stroke": "#D97706", "text": "#78350F", "badge": "#FEF3C7"},
        "living": {"fill": "#F0F9FF", "stroke": "#0284C7", "text": "#0C4A6E", "badge": "#E0F2FE"},
        "parking": {"fill": "#F8FAFC", "stroke": "#475569", "text": "#1E293B", "badge": "#E2E8F0"},
        "utility": {"fill": "#F9FAFB", "stroke": "#6B7280", "text": "#1F2937", "badge": "#F3F4F6"},
        "circulation": {"fill": "#FAF5FF", "stroke": "#7E22CE", "text": "#581C87", "badge": "#F3E8FF"},
    }

    @classmethod
    def render(
        cls,
        plot: PlotInput,
        rooms: List[RoomOutput],
        total_built_area: float,
        utilization_percentage: float,
        circulation_paths: Optional[List[CirculationPathOutput]] = None,
        doors: Optional[List[DoorOutput]] = None,
        windows: Optional[List[WindowOutput]] = None,
        plan_title: str = "SmartPlot — 2D Architectural Layout",
        spatial_breakdown: Optional[SpatialBreakdownOutput] = None,
    ) -> str:
        circulation_paths = circulation_paths or []
        doors = doors or []
        windows = windows or []

        # Determine canvas dimensions with comfortable margins
        margin = 70.0
        header_height = 80.0
        footer_height = 100.0

        p_width = float(plot.plot_width)
        p_length = float(plot.plot_length)
        unit = "ft" if plot.unit.value == "feet" else "m"

        # Viewbox scale calculation (fit within ~800 to 1000 px width)
        target_render_width = 800.0
        scale = target_render_width / p_width
        render_plot_width = p_width * scale
        render_plot_length = p_length * scale

        viewbox_width = render_plot_width + (margin * 2)
        viewbox_height = render_plot_length + header_height + footer_height + (margin * 2)

        plot_origin_x = margin
        plot_origin_y = margin + header_height

        svg_parts: List[str] = []
        svg_parts.append(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {viewbox_width:.1f} {viewbox_height:.1f}" '
            f'width="100%" height="100%" style="font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif; background-color: #FFFFFF;">'
        )

        # Definitions (Patterns, Markers)
        svg_parts.append("<defs>")
        svg_parts.append(
            '<pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">'
            '<path d="M 20 0 L 0 0 0 20" fill="none" stroke="#F1F5F9" stroke-width="1"/>'
            "</pattern>"
        )
        svg_parts.append(
            '<pattern id="corridor_pattern" width="12" height="12" patternUnits="userSpaceOnUse">'
            '<rect width="12" height="12" fill="#F8FAFC" />'
            '<path d="M 0 12 L 12 0 M 6 12 L 12 6 M 0 6 L 6 0" fill="none" stroke="#E2E8F0" stroke-width="0.8" />'
            "</pattern>"
        )
        svg_parts.append("</defs>")

        # Background grid
        svg_parts.append(f'<rect width="{viewbox_width:.1f}" height="{viewbox_height:.1f}" fill="url(#grid)" />')

        # Header Title & Plot Specs
        clean_title = html.escape(plan_title)
        svg_parts.append(
            f'<text x="{margin}" y="36" font-size="20" font-weight="700" fill="#0F172A">{clean_title}</text>'
        )

        # Metrics subtitle
        cov_info = f"Ground Coverage: {utilization_percentage:.1f}%"
        if spatial_breakdown:
            cov_info = f"Net Rooms: {spatial_breakdown.net_room_area:.1f} {unit}² | Corridors: {spatial_breakdown.circulation_area:.1f} {unit}² | Walls: {spatial_breakdown.wall_area:.1f} {unit}²"

        svg_parts.append(
            f'<text x="{margin}" y="58" font-size="11" fill="#64748B">'
            f'Plot: {p_width:.1f} × {p_length:.1f} {unit} ({plot.plot_width * plot.plot_length:.1f} {unit}²) | '
            f'{cov_info} | Entrance: {plot.entrance_orientation.value}'
            f"</text>"
        )

        # Compass Indicator (Top Right)
        compass_cx = viewbox_width - margin - 35
        compass_cy = 45
        svg_parts.append(cls._render_compass(compass_cx, compass_cy, plot.entrance_orientation))

        # Plot Boundary (Outer dashed property line)
        svg_parts.append(
            f'<rect x="{plot_origin_x}" y="{plot_origin_y}" width="{render_plot_width}" height="{render_plot_length}" '
            f'fill="#FFFFFF" stroke="#94A3B8" stroke-width="2" stroke-dasharray="6,4" rx="4" />'
        )

        # Dimension Lines for Plot Outer Boundary
        svg_parts.append(
            f'<line x1="{plot_origin_x}" y1="{plot_origin_y - 12}" x2="{plot_origin_x + render_plot_width}" y2="{plot_origin_y - 12}" '
            f'stroke="#64748B" stroke-width="1.5" />'
        )
        svg_parts.append(
            f'<text x="{plot_origin_x + render_plot_width / 2}" y="{plot_origin_y - 16}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle">'
            f'{p_width:.1f} {unit}'
            f"</text>"
        )

        svg_parts.append(
            f'<line x1="{plot_origin_x - 12}" y1="{plot_origin_y}" x2="{plot_origin_x - 12}" y2="{plot_origin_y + render_plot_length}" '
            f'stroke="#64748B" stroke-width="1.5" />'
        )
        svg_parts.append(
            f'<text x="{plot_origin_x - 16}" y="{plot_origin_y + render_plot_length / 2}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle" transform="rotate(-90 {plot_origin_x - 16} {plot_origin_y + render_plot_length / 2})">'
            f'{p_length:.1f} {unit}'
            f"</text>"
        )

        # 1. Render Circulation Paths (Corridors and Foyers)
        for cp in circulation_paths:
            cpx = plot_origin_x + (cp.x * scale)
            cpy = plot_origin_y + (render_plot_length - ((cp.y + cp.length) * scale))
            cpw = cp.width * scale
            cpl = cp.length * scale

            svg_parts.append(
                f'<rect x="{cpx:.1f}" y="{cpy:.1f}" width="{cpw:.1f}" height="{cpl:.1f}" '
                f'fill="url(#corridor_pattern)" stroke="#CBD5E1" stroke-width="1.5" stroke-dasharray="4,2" />'
            )
            clean_cpname = html.escape(cp.name)
            svg_parts.append(
                f'<text x="{cpx + cpw / 2:.1f}" y="{cpy + cpl / 2:.1f}" font-size="9" font-weight="600" fill="#64748B" text-anchor="middle" letter-spacing="1">'
                f'{clean_cpname.upper()} ({cp.width:.1f}\' WIDE)'
                f"</text>"
            )

        # 2. Render Rooms (Architectural double structural walls)
        for room in rooms:
            rx = plot_origin_x + (room.x * scale)
            ry = plot_origin_y + (render_plot_length - ((room.y + room.length) * scale))
            rw = room.width * scale
            rh = room.length * scale

            color_theme = cls.CATEGORY_COLORS.get(room.category, cls.CATEGORY_COLORS["circulation"])

            # Room background
            svg_parts.append(
                f'<rect x="{rx:.1f}" y="{ry:.1f}" width="{rw:.1f}" height="{rh:.1f}" '
                f'fill="{color_theme["fill"]}" stroke="{color_theme["stroke"]}" stroke-width="2.5" rx="2" />'
            )

            # Room Labels & Dimensions inside room
            center_x = rx + (rw / 2.0)
            center_y = ry + (rh / 2.0)

            clean_name = html.escape(room.name)
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y - 10:.1f}" font-size="11" font-weight="700" fill="{color_theme["text"]}" text-anchor="middle">{clean_name}</text>'
            )
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y + 6:.1f}" font-size="10" font-weight="500" fill="#475569" text-anchor="middle">'
                f'{room.width:.1f} × {room.length:.1f} {unit}'
                f"</text>"
            )
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y + 20:.1f}" font-size="9" fill="#94A3B8" text-anchor="middle">'
                f'({room.area:.1f} {unit}²)'
                f"</text>"
            )

        # 3. Render Windows on Exterior Walls (Blue Sill Line + Glazing)
        for win in windows:
            wx = plot_origin_x + (win.x * scale)
            wy = plot_origin_y + (render_plot_length - (win.y * scale))
            w_span = (win.width * scale) / 2.0

            if win.wall in ["south", "north"]:
                # Horizontal window sill
                svg_parts.append(
                    f'<line x1="{wx - w_span:.1f}" y1="{wy:.1f}" x2="{wx + w_span:.1f}" y2="{wy:.1f}" '
                    f'stroke="#0284C7" stroke-width="4.0" stroke-linecap="square" />'
                )
                svg_parts.append(
                    f'<line x1="{wx - w_span:.1f}" y1="{wy:.1f}" x2="{wx + w_span:.1f}" y2="{wy:.1f}" '
                    f'stroke="#FFFFFF" stroke-width="1.0" />'
                )
            else:
                # Vertical window sill
                svg_parts.append(
                    f'<line x1="{wx:.1f}" y1="{wy - w_span:.1f}" x2="{wx:.1f}" y2="{wy + w_span:.1f}" '
                    f'stroke="#0284C7" stroke-width="4.0" stroke-linecap="square" />'
                )
                svg_parts.append(
                    f'<line x1="{wx:.1f}" y1="{wy - w_span:.1f}" x2="{wx:.1f}" y2="{wy + w_span:.1f}" '
                    f'stroke="#FFFFFF" stroke-width="1.0" />'
                )

        # 4. Render Doors with Cutout and Swing Arcs
        for door in doors:
            dx = plot_origin_x + (door.x * scale)
            dy = plot_origin_y + (render_plot_length - (door.y * scale))
            d_rad = min(door.width * scale, 24.0)

            # Punch white opening through wall
            if door.wall in ["north", "south"]:
                svg_parts.append(
                    f'<line x1="{dx - d_rad / 2:.1f}" y1="{dy:.1f}" x2="{dx + d_rad / 2:.1f}" y2="{dy:.1f}" '
                    f'stroke="#FFFFFF" stroke-width="4.0" />'
                )
            else:
                svg_parts.append(
                    f'<line x1="{dx:.1f}" y1="{dy - d_rad / 2:.1f}" x2="{dx:.1f}" y2="{dy + d_rad / 2:.1f}" '
                    f'stroke="#FFFFFF" stroke-width="4.0" />'
                )

            # Door leaf line and swing arc
            svg_parts.append(
                f'<path d="M {dx - d_rad / 2:.1f} {dy:.1f} A {d_rad:.1f} {d_rad:.1f} 0 0 1 {dx + d_rad / 2:.1f} {dy - d_rad:.1f}" '
                f'fill="none" stroke="#475569" stroke-width="1.2" stroke-dasharray="2,2" />'
            )
            svg_parts.append(
                f'<line x1="{dx - d_rad / 2:.1f}" y1="{dy:.1f}" x2="{dx + d_rad / 2:.1f}" y2="{dy - d_rad:.1f}" '
                f'stroke="#0F172A" stroke-width="1.5" />'
            )

        # 5. Entrance Road & Arrow Indicator
        road_y = plot_origin_y + render_plot_length + 28
        svg_parts.append(
            f'<line x1="{plot_origin_x}" y1="{road_y}" x2="{plot_origin_x + render_plot_width}" y2="{road_y}" '
            f'stroke="#0284C7" stroke-width="3" stroke-dasharray="10,5" />'
        )
        svg_parts.append(
            f'<text x="{plot_origin_x + render_plot_width / 2}" y="{road_y + 18}" font-size="11" font-weight="700" fill="#0369A1" text-anchor="middle">'
            f'MAIN ACCESS ROAD / ENTRANCE ({plot.entrance_orientation.value.upper()})'
            f"</text>"
        )

        # 6. Footer Mandatory Disclaimer (SP-AI-10)
        disclaimer_y = viewbox_height - footer_height + 20
        svg_parts.append(
            f'<rect x="{margin}" y="{disclaimer_y}" width="{render_plot_width}" height="65" '
            f'fill="#FEF2F2" stroke="#EF4444" stroke-width="1" rx="4" />'
        )
        svg_parts.append(
            f'<text x="{margin + 12}" y="{disclaimer_y + 20}" font-size="10" font-weight="700" fill="#991B1B">⚠️ MANDATORY PRELIMINARY NOTICE (SP-AI-10)</text>'
        )
        svg_parts.append(
            f'<text x="{margin + 12}" y="{disclaimer_y + 36}" font-size="9" fill="#7F1D1D">'
            f'This layout is an AI-assisted conceptual preliminary plan and does not constitute a certified architectural'
            f"</text>"
        )
        svg_parts.append(
            f'<text x="{margin + 12}" y="{disclaimer_y + 49}" font-size="9" fill="#7F1D1D">'
            f'or structural drawing. Professional review by a licensed architect is required prior to construction.'
            f"</text>"
        )

        svg_parts.append("</svg>")
        return "".join(svg_parts)

    @classmethod
    def _render_compass(cls, cx: float, cy: float, orientation: OrientationEnum) -> str:
        return (
            f'<g transform="translate({cx},{cy})">'
            f'<circle cx="0" cy="0" r="18" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>'
            f'<polygon points="0,-14 4,-2 -4,-2" fill="#EF4444"/>'
            f'<polygon points="0,14 4,2 -4,2" fill="#94A3B8"/>'
            f'<text x="0" y="-16" font-size="9" font-weight="700" fill="#EF4444" text-anchor="middle">N</text>'
            f'</g>'
        )
