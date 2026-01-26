# Performance Test Results

## Test Environment
- OS: [Your OS]
- CPU: [Your CPU]
- RAM: [Your RAM]

## Startup Time
Target: <50ms

1. Close app completely
2. Run `time npm run tauri dev`
3. Measure time to window appearance

Result: ___ms

## Memory Usage
Target: <30MB

1. Open Activity Monitor/Task Manager
2. Launch CopyMan
3. Record memory usage after 1 minute idle

Result: ___MB

## Search Performance
Target: <20ms average

1. Generate 10,000 test entries
2. Search for various terms
3. Measure response time in browser DevTools Network tab

Results:
- "test": ___ms
- "entry": ___ms
- "1000": ___ms
- Average: ___ms

## Virtual Scrolling
Target: 60 FPS

1. Generate 10,000 test entries
2. Scroll rapidly through list
3. Check FPS in browser DevTools Performance tab

Result: ___FPS

## Clipboard Monitor
Target: <5% CPU idle

1. Leave app running for 5 minutes
2. Monitor CPU usage
3. Verify no memory leaks

Result: ___% CPU avg
