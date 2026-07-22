## Gyroscope Debugging Script
## 
## Usage: Attach to any Node in your scene (e.g., MainScene)
## Check console output and on-screen debug info
## 
## Purpose: Identify exactly why gyro isn't working on your phone

extends Node

@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var cardboard_camera: Node3D = $Head/CardboardVRCamera

# Debug display
var debug_label: Label
var gyro_active: bool = false
var last_gyro_reading: Vector3 = Vector3.ZERO
var frame_count: int = 0

func _ready() -> void:
	# Create debug UI
	_create_debug_label()
	
	# Print immediate diagnostics
	_print_platform_info()
	
	# Check permissions
	_check_permissions()
	
	# Check camera setup
	_check_camera_setup()
	
	# Wait for plugin initialization
	await get_tree().create_timer(1.0).timeout
	_check_sensors()
	
	# Start monitoring
	set_process(true)

func _create_debug_label() -> void:
	"""Create on-screen debug display"""
	debug_label = Label.new()
	debug_label.text = "Initializing..."
	add_child(debug_label)
	
	# Position at top-left
	debug_label.anchor_left = 0.0
	debug_label.anchor_top = 0.0
	debug_label.offset_left = 10
	debug_label.offset_top = 10
	debug_label.add_theme_font_size_override("font_size", 14)
	
	# Make it visible
	debug_label.modulate = Color.WHITE

func _print_platform_info() -> void:
	"""Print basic platform info"""
	print("\n" + "=".repeat(50))
	print("VR CASINO - GYROSCOPE DIAGNOSTICS")
	print("=".repeat(50))
	print("Platform: %s" % OS.get_name())
	print("Engine: Godot %s" % Engine.get_version_info().string)
	print("Device Model: %s" % OS.get_model_name())
	print("=".repeat(50) + "\n")

func _check_permissions() -> void:
	"""Check if required permissions are granted"""
	print("[PERMISSIONS CHECK]")
	
	var permissions = [
		"android.permission.BODY_SENSORS",
		"android.permission.BODY_SENSORS_BACKGROUND",
		"android.permission.ACCESS_FINE_LOCATION"
	]
	
	for perm in permissions:
		var has_perm = OS.has_permission(perm)
		var status = "✓" if has_perm else "✗"
		print("%s %s: %s" % [status, perm.split(".")[-1], has_perm])
	
	# Request sensor permission if missing
	if OS.get_name() == "Android":
		if not OS.has_permission("android.permission.BODY_SENSORS"):
			print("\n⚠ Requesting BODY_SENSORS permission...")
			OS.request_permissions(["android.permission.BODY_SENSORS"])
	
	print()

func _check_camera_setup() -> void:
	"""Verify camera hierarchy is correct"""
	print("[CAMERA SETUP CHECK]")
	
	if OS.get_name() == "Android":
		# Check CardboardVRCamera
		if cardboard_camera == null:
			print("✗ CardboardVRCamera NOT FOUND")
			print("  Expected path: $Head/CardboardVRCamera")
		else:
			print("✓ CardboardVRCamera found")
			print("  - Current: %s" % cardboard_camera.current)
			print("  - Enabled: %s" % cardboard_camera.enabled)
			
			# This is what we need
			if cardboard_camera.current and cardboard_camera.enabled:
				print("  → ✓ Ready for gyro input")
			else:
				print("  → ✗ NOT ready (disabled or not current)")
	else:
		# Check debug camera
		if camera_3d == null:
			print("✗ Camera3D NOT FOUND")
		else:
			print("✓ Camera3D found (Debug Mode)")
	
	print()

func _check_sensors() -> void:
	"""Check if sensors are available"""
	print("[SENSOR AVAILABILITY CHECK]")
	
	# Accelerometer
	var accel = Input.get_accelerometer()
	print("Accelerometer: %s" % ("✓ Available" if accel != Vector3.ZERO else "✗ No data"))
	print("  Value: %s" % accel)
	
	# Gyroscope
	var gyro = Input.get_gyroscope()
	print("Gyroscope: %s" % ("✓ Available" if gyro != Vector3.ZERO else "? No data yet"))
	print("  Value: %s" % gyro)
	
	# Magnetometer
	var mag = Input.get_magnetometer()
	print("Magnetometer: %s" % ("✓ Available" if mag != Vector3.ZERO else "? No data yet"))
	print("  Value: %s" % mag)
	
	print()

func _process(_delta: float) -> void:
	"""Monitor gyroscope continuously"""
	frame_count += 1
	
	# Read gyro every frame
	var gyro_reading = Input.get_gyroscope()
	
	# Check if we're getting data
	if gyro_reading != Vector3.ZERO:
		gyro_active = true
		last_gyro_reading = gyro_reading
	
	# Update debug display every 30 frames (to avoid flickering)
	if frame_count % 30 == 0:
		_update_debug_display(gyro_reading)

func _update_debug_display(gyro: Vector3) -> void:
	"""Update on-screen debug info"""
	var status = "WORKING ✓" if gyro_active else "NOT WORKING ✗"
	var platform = "ANDROID VR" if OS.get_name() == "Android" else "PC DEBUG"
	
	var text = """
[%s]
Platform: %s
Status: %s

Gyro (X,Y,Z):
%.3f, %.3f, %.3f

Perms: %s
Camera: %s
	""" % [
		status,
		platform,
		status,
		gyro.x, gyro.y, gyro.z,
		"OK" if OS.has_permission("android.permission.BODY_SENSORS") else "DENIED",
		"Cardboard" if cardboard_camera and cardboard_camera.current else "Debug"
	]
	
	debug_label.text = text

## QUICK FIX SUGGESTIONS
##
## If you see "NOT WORKING ✗":
##
## 1. Check logs for permission messages
##    → Run: adb logcat -s godot | grep -i permission
##
## 2. If permission denied:
##    → On phone: Settings → Apps → Your App → Permissions → Sensors → ON
##    → Restart app
##
## 3. If "No data":
##    → Redmi Note 11: Settings → Developer Options → Disable Sensors... → OFF
##    → Restart app
##
## 4. If "CardboardVRCamera NOT FOUND":
##    → Plugin missing or not installed
##    → Check res://addons/cardboardvr/ exists
##
## 5. Still broken?
##    → Uninstall: adb uninstall com.yourcompany.yourgame
##    → Export fresh APK with all fixes
##    → Reinstall: adb install app.apk
