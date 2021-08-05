extends Node2D

# Sampling size
const SAMPLE_SIZE = 32

# Frequency range
const FREQ_MIN = 85.0
const FREQ_MAX = 350.0

# Adding tolerances
var TOLERANCE_FREQ_MIN = FREQ_MIN - RandomNumberGenerator.new().randf_range(0.0, 10.0)
var TOLERANCE_FREQ_MAX = FREQ_MAX + RandomNumberGenerator.new().randf_range(0.0, 10.0)

var current_max_freq = 1.0

var speed_scale_weight : float = 0.0

# Rectangle drawing size
const WIDTH = 400
const HEIGHT = 100

const MIN_DB = 60

# Spectrum analyzer effect from the AudioInput bus
var spectrum

func _init_sprite():
  # Don't spin on startup
  $Spinner/AnimatedSprite.frames.set_animation_speed("spin", 0)
  $Spinner/AnimatedSprite.play("spin")

func _draw():
  #warning-ignore:integer_division
  var drawing_w = WIDTH / SAMPLE_SIZE
  
  # Initialize basic data for changing the speed of the spin
  var current_max_freq = 0.0
  var max_magnitude : float = 0
  
  var prev_freq = 0
  
  for i in range(1, SAMPLE_SIZE + 1):
    var freq = i * ((TOLERANCE_FREQ_MAX - TOLERANCE_FREQ_MIN) / SAMPLE_SIZE)
    
    # get_magnitude_for_frequency_range() provides a vector of the left and right channels
    # so getting the length is getting the magnitude of both channels
    var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_freq, freq).length()
    
    #print_debug("Magnitude: ", magnitude)
    
     # Scale height of waveform based on volume
    var energy = clamp((MIN_DB + linear2db(magnitude)) / MIN_DB, 0, 1)
    var drawing_h = energy * HEIGHT
    
    prev_freq = freq
    
    draw_rect(Rect2((drawing_w * i), (HEIGHT - drawing_h), drawing_w, drawing_h), Color.white)
    
    if magnitude > max_magnitude:
      max_magnitude = magnitude
      current_max_freq = freq
  
  # Calculate a weighted value for the scale factor based on "pitch"
  # The higher the pitch, the faster we spin
  if fmod(current_max_freq, TOLERANCE_FREQ_MAX) < 130:
    speed_scale_weight = 0
  elif fmod(current_max_freq, TOLERANCE_FREQ_MAX) < 175:
    speed_scale_weight = 0.2
  elif fmod(current_max_freq, TOLERANCE_FREQ_MAX) < 205:
    speed_scale_weight = 0.5
  elif fmod(current_max_freq, TOLERANCE_FREQ_MAX) < 235:
    speed_scale_weight = 0.75
  else:
    speed_scale_weight = 1.0
  
  print_debug("Freq: ", current_max_freq, ", scale: ", speed_scale_weight, ",Magnitude: ", max_magnitude)
  
  # Setting the speed scale to implicitly determine the frame speed
  #$Spinner/AnimatedSprite.speed_scale = speed_scale_weight
  #$Spinner/AnimatedSprite.frames.set_animation_speed("spin", 30.0)
  
  # Manually set the speed of the animation
  var fps = speed_scale_weight * 30.0  
  $Spinner/AnimatedSprite.frames.set_animation_speed("spin", fps)
  print_debug("Speed: ", fps)

func _process(_delta):
  update()

func _ready():
  # The master audio is the first channel and the microphone input is the second channel
  var idx = AudioServer.get_bus_index("AudioInput")
  spectrum = AudioServer.get_bus_effect_instance(idx, 1)
  
  # Set up spinner
  _init_sprite()

func _input(event):
  if event is InputEventKey and not event.echo:
    if event.scancode == KEY_S:
      $Spinner/AnimatedSprite.stop()
    elif event.scancode == KEY_P:
      $Spinner/AnimatedSprite.play("spin")
