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
    } else if (requirements.floors !== undefined && requirements.floors > 2) {
      errors.push({
        field: 'requirements.floors',
        message: 'Multi-floor generation supports up to 2 floors (Ground + First Floor) in Phase 6.',
      });
    }

    // Floor-specific validation
    if (requirements.floors === 1 && requirements.first_floor) {
      errors.push({
        field: 'requirements.first_floor',
        message: 'first_floor requirements cannot be specified for single-story layouts (floors=1).',
      });
    }

    if (requirements.ground_floor) {
      if (typeof requirements.ground_floor !== 'object') {
        errors.push({ field: 'requirements.ground_floor', message: 'ground_floor must be an object.' });
      } else {
        if (requirements.ground_floor.bedrooms !== undefined && (typeof requirements.ground_floor.bedrooms !== 'number' || requirements.ground_floor.bedrooms < 0)) {
          errors.push({ field: 'requirements.ground_floor.bedrooms', message: 'Ground floor bedrooms must be an integer (>= 0).' });
        }
        if (requirements.ground_floor.bathrooms !== undefined && (typeof requirements.ground_floor.bathrooms !== 'number' || requirements.ground_floor.bathrooms < 0)) {
          errors.push({ field: 'requirements.ground_floor.bathrooms', message: 'Ground floor bathrooms must be an integer (>= 0).' });
        }
      }
    }

    if (requirements.first_floor) {
      if (typeof requirements.first_floor !== 'object') {
        errors.push({ field: 'requirements.first_floor', message: 'first_floor must be an object.' });
      } else {
        if (requirements.first_floor.bedrooms !== undefined && (typeof requirements.first_floor.bedrooms !== 'number' || requirements.first_floor.bedrooms < 0)) {
          errors.push({ field: 'requirements.first_floor.bedrooms', message: 'First floor bedrooms must be an integer (>= 0).' });
        }
        if (requirements.first_floor.bathrooms !== undefined && (typeof requirements.first_floor.bathrooms !== 'number' || requirements.first_floor.bathrooms < 0)) {
          errors.push({ field: 'requirements.first_floor.bathrooms', message: 'First floor bathrooms must be an integer (>= 0).' });
        }
      }
    }

    if (requirements.ground_floor && requirements.first_floor) {
      const gfBeds = requirements.ground_floor.bedrooms || 0;
      const f1Beds = requirements.first_floor.bedrooms || 0;
      if (gfBeds + f1Beds < 1) {
        errors.push({ field: 'requirements', message: 'At least 1 bedroom must be specified across the residence.' });
      }
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

function validatePlanEditRequest(req, res, next) {
  const { plot, rooms } = req.body || {};

  if (!plot) {
    return res.status(400).json({
      status: 'error',
      code: 'MISSING_PLOT_PAYLOAD',
      message: 'Plot specifications object is required under "plot" field.',
    });
  }

  if (!rooms || !Array.isArray(rooms) || rooms.length === 0) {
    return res.status(400).json({
      status: 'error',
      code: 'INVALID_ROOMS_PAYLOAD',
      message: 'Rooms array is required and must contain at least one room.',
    });
  }

  next();
}

module.exports = {
  validatePlanGenerateRequest,
  validatePlanEditRequest,
};
