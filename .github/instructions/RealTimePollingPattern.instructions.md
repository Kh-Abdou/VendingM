````instructions
// filepath: c:\Users\Khobz\Documents\Projects\PFE\.github\instructions\RealTimePollingPattern.instructions.md
---
applyTo: '**'
---
# Real-Time Polling Pattern - Best Practices Guide

## 🎯 Purpose
This guide provides best practices for implementing real-time polling patterns in Flutter applications that communicate with backend APIs and hardware components. Use this as a reference for creating robust, user-friendly real-time interactions.

## 🔄 Real-Time Polling Pattern Overview

Real-time polling is used when:
- An action takes time to complete (hardware operations, file processing, etc.)
- You need to show progress to users
- Multiple components need to coordinate (frontend, backend, hardware)

**Basic Flow:**
1. Frontend triggers action via API call
2. Backend starts processing and returns tracking ID
3. Frontend polls status endpoint using the ID
4. Backend/hardware updates status as work progresses
5. Frontend receives final status and shows result

## 🛠️ Implementation Best Practices

### **1. API Route Consistency**
Ensure frontend and backend use identical route paths:
```
✅ GOOD: Both use /api/orders/status/:id
❌ BAD: Frontend calls /order/status/:id, backend expects /orders/status/:id
```

### **2. Status Value Standards**
Use consistent, uppercase status values:
- `PENDING` - Action in progress
- `COMPLETED` - Action successful
- `FAILED` - Action failed
- `TIMEOUT` - Action took too long

### **3. Polling Logic Rules**
- Only stop polling on final statuses (`COMPLETED`, `FAILED`, `TIMEOUT`)
- Continue polling on intermediate statuses (`PENDING`, `PROCESSING`)
- Implement maximum attempt limits to prevent infinite loops
- Add delays between polling requests (typically 1-2 seconds)

### **4. Response Format Consistency**
Always return JSON responses with standard structure:
```json
{
  "id": "unique-identifier",
  "status": "PENDING|COMPLETED|FAILED",
  "success": true|false,
  "message": "Human readable status",
  "data": { /* action-specific data */ }
}
```

### **5. Error Handling Strategy**
- Network errors: Continue polling (temporary issues)
- HTTP 4xx errors: Stop polling (client error)
- HTTP 5xx errors: Retry with exponential backoff
- JSON parse errors: Log and treat as temporary failure

## 📱 User Experience Guidelines

### **Loading States**
- Show immediate feedback when action starts
- Use non-dismissible dialogs for critical operations
- Display progress indicators or status messages
- Provide estimated time when possible

### **Success/Failure Feedback**
- Clear success messages with next steps
- Specific error messages with troubleshooting hints
- Allow users to retry failed operations
- Log detailed error information for debugging

### **Timeout Handling**
- Set reasonable timeout limits (30-60 seconds typical)
- Gracefully handle timeouts with clear messaging
- Offer retry options for timed-out operations
- Consider background processing for long operations

## 🔧 Technical Implementation Tips

### **Polling Loop Structure**
```dart
// Pseudo-code pattern
bool isComplete = false;
bool isSuccessful = false;
int attempts = 0;
const maxAttempts = 30;

while (!isComplete && attempts < maxAttempts) {
  attempts++;
  await delay(1000); // Wait 1 second
  
  try {
    final status = await checkStatus(actionId);
    
    if (status.isFinal()) {
      isComplete = true;
      isSuccessful = status.isSuccess();
      break;
    }
    // Continue polling for non-final statuses
    
  } catch (error) {
    // Handle but don't stop polling for network errors
    logError(error);
  }
}

// Handle timeout case
if (!isComplete) {
  isSuccessful = false;
  message = "Operation timed out";
}
```

### **Backend Status Updates**
- Update status atomically in database
- Use consistent status values across all endpoints
- Include timestamps for debugging
- Provide detailed error messages when operations fail

### **Hardware Integration**
- Use consistent network configurations (IP addresses, ports)
- Implement retry logic for hardware communication
- Handle hardware disconnection gracefully
- Provide fallback mechanisms when possible

## 🚨 Common Pitfalls to Avoid

1. **Route Mismatches**: Frontend and backend using different endpoint paths
2. **Case Sensitivity**: Mixing uppercase/lowercase in status values
3. **Early Termination**: Stopping polling on non-final statuses
4. **Network Address Conflicts**: Different components using different IPs
5. **Missing Error Handling**: Not handling network failures or timeouts
6. **Poor User Feedback**: No loading states or unclear error messages
7. **Infinite Polling**: No maximum attempt limits or timeout handling

## ✅ Testing Checklist

### **API Testing**
- [ ] All endpoints return JSON (not HTML error pages)
- [ ] Route paths match between frontend and backend
- [ ] Status values are consistent and properly cased
- [ ] Error responses include helpful messages

### **Polling Logic Testing**
- [ ] Continues polling on intermediate statuses
- [ ] Stops polling on final statuses
- [ ] Handles network errors gracefully
- [ ] Respects timeout limits
- [ ] Provides appropriate user feedback

### **Integration Testing**
- [ ] Frontend can communicate with backend
- [ ] Backend can communicate with hardware
- [ ] All components use consistent network configuration
- [ ] End-to-end workflows complete successfully

### **User Experience Testing**
- [ ] Loading states appear immediately
- [ ] Success messages are clear and helpful
- [ ] Error messages provide actionable information
- [ ] Users can retry failed operations
- [ ] Timeouts are handled gracefully

## 🎯 Success Metrics

A well-implemented real-time polling system should achieve:
- **Reliability**: 99%+ successful completion rate under normal conditions
- **Responsiveness**: Immediate user feedback when actions start
- **Clarity**: Users always understand current status and next steps
- **Robustness**: Graceful handling of network issues and failures
- **Performance**: Minimal resource usage with appropriate polling intervals

Use these guidelines to create real-time features that provide excellent user experiences while maintaining system reliability and performance.
````
