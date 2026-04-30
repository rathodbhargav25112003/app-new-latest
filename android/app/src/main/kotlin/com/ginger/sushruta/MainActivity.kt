package com.ginger.sushruta

import android.os.Bundle
import io.flutter.embedding.android.FlutterAppCompatActivity
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.view.animation.Animation
import android.animation.Animator
import android.animation.AnimatorListenerAdapter

class MainActivity : FlutterAppCompatActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val VIEW_MONITORING_DELAY = 500L // 500ms delay for view monitoring
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoringViews = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Apply comprehensive detached view crash fix
        applyComprehensiveDetachedViewCrashFix()
    }
    
    /**
     * Comprehensive solution to prevent detached view animation crashes
     * Includes continuous monitoring and global animation state management
     */
    private fun applyComprehensiveDetachedViewCrashFix() {
        // Initial application
        applyDetachedViewCrashFix()
        
        // Start continuous monitoring for dynamically created views
        startContinuousViewMonitoring()
        
        // Apply global animation state management
        applyGlobalAnimationStateManagement()
    }
    
    /**
     * Implements the OnAttachStateChangeListener solution to prevent animation crashes
     * Enhanced version with better error handling and coverage
     */
    private fun applyDetachedViewCrashFix() {
        // Wait for the view tree to be ready
        window.decorView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                // Remove the listener to avoid multiple calls
                window.decorView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                
                // Apply the fix to all views in the hierarchy
                applyAttachStateListenerToViewHierarchy(window.decorView)
                
                // Also apply to any existing Nutrient SDK views
                findAndProtectNutrientViews(window.decorView)
            }
        })
    }
    
    /**
     * Starts continuous monitoring for dynamically created views
     * This catches views created by Nutrient SDK after initial setup
     */
    private fun startContinuousViewMonitoring() {
        if (isMonitoringViews) return
        isMonitoringViews = true
        
        val monitorRunnable = object : Runnable {
            override fun run() {
                if (!isFinishing && !isDestroyed) {
                    findAndProtectNutrientViews(window.decorView)
                    handler.postDelayed(this, VIEW_MONITORING_DELAY)
                }
            }
        }
        
        handler.postDelayed(monitorRunnable, VIEW_MONITORING_DELAY)
    }
    
    /**
     * Applies global animation state management to prevent crashes
     */
    private fun applyGlobalAnimationStateManagement() {
        // Override animation methods globally for this activity
        window.decorView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                // This will be called whenever the view hierarchy changes
                // Apply protection to any new views
                findAndProtectNutrientViews(window.decorView)
            }
        })
    }
    
    /**
     * Recursively applies OnAttachStateChangeListener to all views in the hierarchy
     * Enhanced version with better coverage
     */
    private fun applyAttachStateListenerToViewHierarchy(view: View) {
        // Add listener to current view if it's a PlatformView or has animations
        if (shouldApplyAttachStateListener(view)) {
            addAttachStateChangeListener(view)
        }
        
        // Recursively apply to child views
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                applyAttachStateListenerToViewHierarchy(view.getChildAt(i))
            }
        }
    }
    
    /**
     * Finds and protects all Nutrient SDK related views
     * More comprehensive detection of Nutrient/PSPDFKit components
     */
    private fun findAndProtectNutrientViews(rootView: View) {
        if (rootView is ViewGroup) {
            for (i in 0 until rootView.childCount) {
                val child = rootView.getChildAt(i)
                if (isNutrientRelatedView(child)) {
                    addAttachStateChangeListener(child)
                }
                findAndProtectNutrientViews(child)
            }
        }
    }
    
    /**
     * Enhanced detection of views that should have the OnAttachStateChangeListener applied
     * More comprehensive coverage of Nutrient/PSPDFKit components
     */
    private fun shouldApplyAttachStateListener(view: View): Boolean {
        val viewClassName = view.javaClass.simpleName
        val viewPackageName = view.javaClass.`package`?.name ?: ""
        
        // Apply to Nutrient/PSPDFKit toolbar components and any view with animations
        return viewClassName.contains("Toolbar") ||
               viewClassName.contains("Button") ||
               viewClassName.contains("ImageButton") ||
               viewClassName.contains("CoordinatorLayout") ||
               viewClassName.contains("RippleComponent") ||
               viewClassName.contains("PlatformView") ||
               viewClassName.contains("RippleDrawable") ||
               viewClassName.contains("MaterialButton") ||
               viewClassName.contains("FloatingActionButton") ||
               viewPackageName.contains("pspdfkit") ||
               viewPackageName.contains("nutrient") ||
               viewPackageName.contains("com.pspdfkit") ||
               viewPackageName.contains("com.nutrient") ||
               view.isClickable ||
               view.isFocusable ||
               view.hasOnClickListeners()
    }
    
    /**
     * Enhanced detection of Nutrient-related views
     */
    private fun isNutrientRelatedView(view: View): Boolean {
        val viewClassName = view.javaClass.simpleName
        val viewPackageName = view.javaClass.`package`?.name ?: ""
        
        return viewClassName.contains("Toolbar") ||
               viewClassName.contains("Button") ||
               viewClassName.contains("ImageButton") ||
               viewClassName.contains("CoordinatorLayout") ||
               viewClassName.contains("RippleComponent") ||
               viewClassName.contains("ToolbarCoordinatorLayout") ||
               viewClassName.contains("PlatformView") ||
               viewPackageName.contains("pspdfkit") ||
               viewPackageName.contains("nutrient") ||
               viewPackageName.contains("com.pspdfkit") ||
               viewPackageName.contains("com.nutrient") ||
               view.isClickable ||
               view.isFocusable
    }
    
    /**
     * Enhanced OnAttachStateChangeListener with comprehensive animation cancellation
     * Based on the blog post solution for detached view animations
     */
    private fun addAttachStateChangeListener(view: View) {
        // Check if listener is already added to avoid duplicates
        if (view.getTag(R.id.attach_state_listener_added) == true) {
            return
        }
        
        view.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                Log.d(TAG, "View attached: ${v.javaClass.simpleName}")
                // Now it is safe to start animations
                // The view is properly attached to the window
            }
            
            override fun onViewDetachedFromWindow(v: View) {
                Log.d(TAG, "View detached: ${v.javaClass.simpleName}")
                // Comprehensive animation cancellation to prevent crashes
                cancelAllAnimationsComprehensive(v)
            }
        })
        
        // Mark that listener has been added to prevent duplicates
        view.setTag(R.id.attach_state_listener_added, true)
    }
    
    /**
     * Comprehensive animation cancellation to prevent all types of animation crashes
     */
    private fun cancelAllAnimationsComprehensive(view: View) {
        try {
            // Cancel view animations
            view.clearAnimation()
            
            // Cancel property animators
            view.animate().cancel()
            
            // Cancel any running animators with multiple properties
            view.animate()
                .setDuration(0)
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .translationX(0f)
                .translationY(0f)
                .rotation(0f)
                .cancel()
            
            // Cancel any ripple effects
            try {
                view.isClickable = false
                view.isFocusable = false
                view.isFocusableInTouchMode = false
            } catch (e: Exception) {
                Log.w(TAG, "Error disabling view interactions: ${e.message}")
            }
            
            // Cancel any background animations
            try {
                view.background?.let { background ->
                    if (background is android.graphics.drawable.AnimationDrawable) {
                        background.stop()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error canceling background animation: ${e.message}")
            }
            
        } catch (e: Exception) {
            Log.w(TAG, "Error in comprehensive animation cancellation: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isMonitoringViews = false
        handler.removeCallbacksAndMessages(null)
    }
}