"""Scalable Vector Graphics (SVG) 2D Floor Plan Renderer per SP-AI-07 and SP-AI-10."""
import html
from typing import List
from backend.app.schemas.plot import OrientationEnum, PlotInput
from backend.app.schemas.response import MANDATORY_DISCLAIMER, RoomOutput


class SVGFloorPlanRenderer:
    """Renders proportionally scaled 2D architectural SVG floor plans with room labels, dimensions, and disclaimer."""

    CATEGORY_COLORS = {
        "bedroom": {"fill": "#EAE6F8", "stroke": "#5B4EB1", "text": "#312678"},
        "bathroom": {"fill": "#E0F4F7", "stroke": "#0E7490", "text": "#155E75"},
        "kitchen": {"fill": "#FEF3C7", "stroke": "#D97706", "text": "#92400E"},
        "living": {"fill": "#E0F2FE", "stroke": "#0284C7", "text": "#0369A1"},
        "parking": {"fill": "#F1F5F9", "stroke": "#64748B", "text": "#334155"},
        "utility": {"fill": "#F3F4F6", "stroke": "#6B7280", "text": "#374151"},
        "circulation": {"fill": "#FAF5FF", "stroke": "#9333EA", "text": "#6B21A8"},
    }

    @classmethod
    def render(
        cls,
        plot: PlotInput,
        rooms: List[RoomOutput],
        total_built_area: float,
        utilization_percentage: float,
    ) -> str:
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

        # Coordinate transformation helper: SVG (0,0) is top-left
        # Plot Y=0 is front (bottom in our visual orientation facing road)
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
            '<marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">'
            '<path d="M 0 0 L 10 5 L 0 10 z" fill="#2563EB" />'
            "</marker>"
        )
        svg_parts.append("</defs>")

        # Background grid
        svg_parts.append(f'<rect width="{viewbox_width:.1f}" height="{viewbox_height:.1f}" fill="url(#grid)" />')

        # Header Title & Plot Specs
        svg_parts.append(
            f'<text x="{margin}" y="38" font-size="20" font-weight="700" fill="#0F172A">SmartPlot — 2D Architectural Layout</text>'
        )
        svg_parts.append(
            f'<text x="{margin}" y="60" font-size="12" fill="#64748B">'
            f'Plot: {p_width:.1f} × {p_length:.1f} {unit} ({plot.plot_width * plot.plot_length:.1f} {unit}²) | '
            f'Built Area: {total_built_area:.1f} {unit}² | Ground Coverage: {utilization_percentage:.1f}% | '
            f'Entrance: {plot.entrance_orientation.value}'
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
        # Top dimension (Width)
        svg_parts.append(
            f'<line x1="{plot_origin_x}" y1="{plot_origin_y - 12}" x2="{plot_origin_x + render_plot_width}" y2="{plot_origin_y - 12}" '
            f'stroke="#64748B" stroke-width="1.5" />'
        )
        svg_parts.append(
            f'<text x="{plot_origin_x + render_plot_width / 2}" y="{plot_origin_y - 16}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle">'
            f'{p_width:.1f} {unit}'
            f"</text>"
        )

        # Left dimension (Length)
        svg_parts.append(
            f'<line x1="{plot_origin_x - 12}" y1="{plot_origin_y}" x2="{plot_origin_x - 12}" y2="{plot_origin_y + render_plot_length}" '
            f'stroke="#64748B" stroke-width="1.5" />'
        )
        svg_parts.append(
            f'<text x="{plot_origin_x - 16}" y="{plot_origin_y + render_plot_length / 2}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle" transform="rotate(-90 {plot_origin_x - 16} {plot_origin_y + render_plot_length / 2})">'
            f'{p_length:.1f} {unit}'
            f"</text>"
        )

        # Render Rooms
        for room in rooms:
            rx = plot_origin_x + (room.x * scale)
            # Invert Y so Y=0 is at bottom (front towards road)
            ry = plot_origin_y + (render_plot_length - ((room.y + room.length) * scale))
            rw = room.width * scale
            rh = room.length * scale

            color_theme = cls.CATEGORY_COLORS.get(room.category, cls.CATEGORY_COLORS["circulation"])

            # Room background and structural walls
            svg_parts.append(
                f'<rect x="{rx:.1f}" y="{ry:.1f}" width="{rw:.1f}" height="{rh:.1f}" '
                f'fill="{color_theme["fill"]}" stroke="{color_theme["stroke"]}" stroke-width="2.5" rx="2" />'
            )

            # Room Labels & Dimensions inside room
            center_x = rx + (rw / 2.0)
            center_y = ry + (rh / 2.0)

            clean_name = html.escape(room.name)
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y - 8:.1f}" font-size="11" font-weight="700" fill="{color_theme["text"]}" text-anchor="middle">{clean_name}</text>'
            )
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y + 8:.1f}" font-size="10" font-weight="500" fill="#475569" text-anchor="middle">'
                f'{room.width:.1f} × {room.length:.1f} {unit}'
                f"</text>"
            )
            svg_parts.append(
                f'<text x="{center_x:.1f}" y="{center_y + 22:.1f}" font-size="9" fill="#94A3B8" text-anchor="middle">'
                f'({room.area:.1f} {unit}²)'
                f"</text>"
            )

            # Door swing indication (drawn at corner)
            door_size = min(14.0, rw * 0.25, rh * 0.25)
            svg_parts.append(
                f'<path d="M {rx:.1f} {ry + rh:.1f} A {door_size:.1f} {door_size:.1f} 0 0 1 {rx + door_size:.1f} {ry + rh - door_size:.1f}" '
                f'fill="none" stroke="{color_theme["stroke"]}" stroke-width="1.2" stroke-dasharray="2,2" />'
            )

        # Entrance Road & Arrow Indicator
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

        # Footer Mandatory Disclaimer (SP-AI-10)
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
