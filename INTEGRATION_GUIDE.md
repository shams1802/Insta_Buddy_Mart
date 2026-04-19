# 🚀 Insta Buddy Mart - Integration & Android Simulator Guide

## ✅ Integration Status

Your **backend** and **frontend** are now **fully integrated**! Here's what's been done:

### Backend Configuration ✓
- API Gateway running on **port 3000**
- Routes configured for all microservices:
  - IAM Service (port 3003)
  - Chat Service (port 3001)
  - Payment Service (port 3002)
- CORS enabled for frontend communication

### Frontend Configuration ✓
- **API Base URL**: `http://10.0.2.2:3000/api/v1` (Android emulator standard)
- **Modern Color Scheme**: 
  - Primary: Vibrant Purple (#7C3AED)
  - Secondary: Cyan (#06B6D4)
  - Accent: Coral Orange (#FF6B35)
- **Enhanced Design**: Improved product cards, gradients, and animations

---

## 🎨 Design Improvements Made

✨ **New Color Palette**:
- Deep blue-black backgrounds (#0F172A)
- Sleek slate surfaces (#1E293B, #334155)
- Vibrant accent colors for better contrast
- Improved gradient overlays

🎯 **Enhanced UI Components**:
- Product cards with better typography and spacing
- Improved shadow effects for depth
- Gradient button effects
- Better color-coded pricing display
- Enhanced icon sizing and clarity

---

## 🏃 How to Run Everything

### **Step 1: Start the Backend Services**

Open **Terminal 1** and run:

```bash
cd d:\Software\Insta_Buddy_Mart\backend\API_Gateway
npm start
```

**Expected Output**:
```
✓ Environment: development
✓ Registered services:
  → IAM Service: http://localhost:3003
  → Chat Service: http://localhost:3001
  → Payment Service: http://localhost:3002
```

---

### **Step 2: Set Up Android SDK Path (One-time Setup)**

**Important**: The `emulator` command needs to be in your PATH.

#### Option A: Permanent Setup (Recommended)

1. **Press `Win + X`** → Click **System** (or open Settings)
2. Click **Advanced system settings**
3. Click **Environment Variables**
4. Under **User variables**, click **New**:
   - Variable name: `ANDROID_SDK_ROOT`
   - Variable value: `%LOCALAPPDATA%\Android\Sdk`
5. Click **OK**
6. Find **Path** in User variables → Click **Edit** → **New**
7. Add: `%LOCALAPPDATA%\Android\Sdk\emulator`
8. Click **OK** and **restart your terminal**

#### Option B: Quick Test (Current Terminal Only)

Run:
```bash
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -list-avds
```

---

### **Step 3: Start Android Emulator**

Open **Terminal 2** and run:

```bash
# List available virtual devices
emulator -list-avds

# Start your emulator (replace with your AVD name)
emulator -avd Pixel_5_API_31
```

**Note**: Replace `Pixel_5_API_31` with your actual AVD name from the list.

**Wait** for the emulator to fully load (this takes 1-2 minutes).

---

### **Step 4: Run Flutter App on Emulator**

Open **Terminal 3** and run:

```bash
cd d:\Software\Insta_Buddy_Mart\frontend
flutter pub get
flutter run
```

**The app will automatically**:
- Detect the running emulator
- Build the APK
- Install and launch on the emulator

**Expected Output**:
```
Launching lib/main.dart on Android device...
...
✓ Built build/app/outputs/flutter-apk/app-release.apk
✓ Installed build/app/outputs/flutter-apk/app-release.apk
✓ Insta Buddy Mart app started
```

---

## 🔧 Complete Terminal Commands (All at Once)

### Terminal 1 - Backend
```bash
cd d:\Software\Insta_Buddy_Mart\backend\API_Gateway && npm start
```

### Terminal 2 - Android Emulator
```bash
emulator -list-avds
# Then:
emulator -avd Pixel_5_API_31
```

### Terminal 3 - Flutter Frontend
```bash
cd d:\Software\Insta_Buddy_Mart\frontend && flutter pub get && flutter run
```

---

## ✨ App Features Ready to Test

Once the app is running on the emulator, you can test:

✅ **Authentication**
- Login screen with modern design
- Registration functionality
- JWT token management

✅ **Home Screen**
- Trending products showcase
- Real-time stats (Orders, Messages, Wallet)
- Search functionality
- Product grid with new design

✅ **Navigation**
- Bottom navigation (Home, Chat, Orders, Profile)
- Smooth page transitions
- Modern color-coded icons

✅ **Backend Integration**
- All API calls routed through the gateway
- Authentication endpoints working
- Chat system integration ready
- Payment service integration ready

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **`emulator` command not found** | Add Android SDK to PATH (see Step 2) |
| **Port 3000 already in use** | Run `netstat -ano \| findstr :3000`, then `taskkill /PID <PID> /F` |
| **Emulator won't start** | Ensure VT-x/AMD-V virtualization is enabled in BIOS |
| **App can't connect to backend** | Verify backend is running on localhost:3000 |
| **Flutter not found** | Install Flutter from [flutter.dev](https://flutter.dev) |
| **AVD not showing in list** | Create a new AVD using Android Studio → Virtual Device Manager |

---

## 📱 Testing the Connection

### 1. Verify Backend is Running
Open browser and navigate to:
```
http://localhost:3000/api/v1/health
```
(or any API endpoint)

### 2. Check Emulator Connectivity
In the emulator, open the browser and try:
```
http://10.0.2.2:3000/api/v1/health
```

### 3. Test Login
In the app, try logging in with test credentials to verify the backend connection works.

---

## 🎯 Next Steps

1. **Start backend** (Terminal 1)
2. **Start emulator** (Terminal 2)
3. **Run Flutter app** (Terminal 3)
4. **Test login** with credentials
5. **Explore app** features

---

## 📚 Additional Resources

- Flutter Documentation: https://flutter.dev/docs
- Android Emulator Docs: https://developer.android.com/studio/run/emulator
- Express.js Documentation: https://expressjs.com

---

**Happy coding! 🎉**

Need help? Make sure all three terminals are running simultaneously and wait for the emulator to fully load before launching the app.
