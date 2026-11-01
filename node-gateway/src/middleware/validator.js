/**
 * Gateway request validation middleware per SP-AI-01, SP-AI-03, SP-AI-04, and SP-NFR-SEC-04.
 */

const ALLOWED_ORIENTATIONS = [
  'north', 'south', 'east', 'west',
  'north-east', 'northwest', 'north-west', 'northeast',
  'south-east', 'southwest', 'south-west', 'southeast',
  'ne', 'nw', 'se', 'sw'
];

function validatePlanGenerateRequest(req, res, next) {
  const { plot, requirements } = req.body || {};

  if (!plot) {
    return res.status(400).json({
      status: 'error',
      code: 'MISSING_PLOT_PAYLOAD',
      message: 'Plot specifications object is required under "plot" field (SP-AI-01).',
    });
  }

  const errors = [];

  // 1. Validate plot length
  if (plot.plot_length === undefined || plot.plot_length === null) {
    errors.push({ field: 'plot.plot_length', message: 'Plot length is required (SP-AI-01).' });
  } else if (typeof plot.plot_length !== 'number' || isNaN(plot.plot_length) || plot.plot_length <= 0) {
    errors.push({ field: 'plot.plot_length', message: 'Plot length must be a positive numeric value (SP-AI-03).' });
  }

  // 2. Validate plot width
  if (plot.plot_width === undefined || plot.plot_width === null) {
    errors.push({ field: 'plot.plot_width', message: 'Plot width is required (SP-AI-01).' });
  } else if (typeof plot.plot_width !== 'number' || isNaN(plot.plot_width) || plot.plot_width <= 0) {
    errors.push({ field: 'plot.plot_width', message: 'Plot width must be a positive numeric value (SP-AI-03).' });
  }

  // 3. Validate front width
  if (plot.front_width === undefined || plot.front_width === null) {
    errors.push({ field: 'plot.front_width', message: 'Front width is required (SP-AI-01).' });
  } else if (typeof plot.front_width !== 'number' || isNaN(plot.front_width) || plot.front_width <= 0) {
    errors.push({ field: 'plot.front_width', message: 'Front width must be a positive numeric value (SP-AI-03).' });
  }

  // 4. Validate entrance orientation
  if (!plot.entrance_orientation) {
    errors.push({ field: 'plot.entrance_orientation', message: 'Entrance orientation is required (SP-AI-01).' });
  } else if (
    typeof plot.entrance_orientation !== 'string' ||
    !ALLOWED_ORIENTATIONS.includes(plot.entrance_orientation.trim().toLowerCase().replace('_', '-'))
  ) {
    errors.push({
      field: 'plot.entrance_orientation',
      message: `Invalid orientation '${plot.entrance_orientation}'. Permitted values: North, South, East, West, North-East, North-West, South-East, South-West (SP-AI-03).`,
    });
  }

  // 5. Validate optional layout requirements if present
  if (requirements) {
    if (requirements.bedrooms !== undefined && (typeof requirements.bedrooms !== 'number' || requirements.bedrooms < 1)) {
      errors.push({ field: 'requirements.bedrooms', message: 'Bedrooms must be a positive integer (minimum 1).' });
    }
    if (requirements.bathrooms !== undefined && (typeof requirements.bathrooms !== 'number' || requirements.bathrooms < 1)) {
      errors.push({ field: 'requirements.bathrooms', message: 'Bathrooms must be a positive integer (minimum 1).' });
    }
    if (requirements.floors !== undefined && (typeof requirements.floors !== 'number' || requirements.floors < 1)) {
      errors.push({ field: 'requirements.floors', message: 'Floors must be a positive integer (minimum 1).' });
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      status: 'error',
      code: 'VALIDATION_FAILED',
      message: 'One or more request parameters failed validation (SP-AI-03, SP-AI-04).',
      details: { errors },
    });
  }

  next();
}

module.exports = {
  validatePlanGenerateRequest,
};
