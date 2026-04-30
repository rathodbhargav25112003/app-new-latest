package com.ginger.sushruta

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.util.Log

/**
 * Custom wrapper for Nutrient SDK toolbar views to prevent detached view animation crashes
 * Implements the OnAttachStateChangeListener solution from the blog post
 */
class NutrientToolbarWrapper @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {
    
    companion object {
        private const val TAG = "NutrientToolbarWrapper"
    }
    
    init {
        // Apply the detached view crash fix when this wrapper is created
        applyDetachedViewCrashFix()
    }
    
    /**
     * Applies the OnAttachStateChangeListener solution to prevent animation crashes
     */
    private fun applyDetachedViewCrashFix() {
        // Wait for the view to be attached before applying listeners
        addOnAttachStateChangeListener(object : OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                Log.d(TAG, "NutrientToolbarWrapper attached to window")
                // Now it's safe to apply listeners to child views
                applyAttachStateListenerToChildren()
            }
            
            override fun onViewDetachedFromWindow(v: View) {
                Log.d(TAG, "NutrientToolbarWrapper detached from window")
                // Cancel any ongoing animations to prevent crashes
                cancelAllAnimations(v)
            }
        })
    }
    
    /**
     * Applies OnAttachStateChangeListener to all child views that might have animations
     */
    private fun applyAttachStateListenerToChildren() {
        for (i in 0 until childCount) {
            val child = getChildAt(i)
            if (isNutrientToolbarComponent(child)) {
                addAttachStateChangeListener(child)
            }
            
            // Recursively apply to child view groups
            if (child is ViewGroup) {
                applyAttachStateListenerToViewGroup(child)
            }
        }
    }
    
    /**
     * Recursively applies OnAttachStateChangeListener to ViewGroup children
     */
    private fun applyAttachStateListenerToViewGroup(viewGroup: ViewGroup) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            if (isNutrientToolbarComponent(child)) {
                addAttachStateChangeListener(child)
            }
            
            if (child is ViewGroup) {
                applyAttachStateListenerToViewGroup(child)
            }
        }
    }
    
    /**
     * Determines if a view is a Nutrient/PSPDFKit toolbar component that needs protection
     */
    private fun isNutrientToolbarComponent(view: View): Boolean {
        val viewClassName = view.javaClass.simpleName
        
        return viewClassName.contains("Toolbar") ||
               viewClassName.contains("Button") ||
               viewClassName.contains("ImageButton") ||
               viewClassName.contains("CoordinatorLayout") ||
               viewClassName.contains("RippleComponent") ||
               viewClassName.contains("ToolbarCoordinatorLayout") ||
               viewClassName.contains("com.pspdfkit") ||
               viewClassName.contains("com.nutrient") ||
               view.isClickable ||
               view.isFocusable
    }
    
    /**
     * Adds OnAttachStateChangeListener to prevent animation crashes
     * Based on the blog post solution for detached view animations
     */
    private fun addAttachStateChangeListener(view: View) {
        // Check if listener is already added to avoid duplicates
        if (view.getTag(R.id.attach_state_listener_added) == true) {
            return
        }
        
        view.addOnAttachStateChangeListener(object : OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                Log.d(TAG, "Nutrient component attached: ${v.javaClass.simpleName}")
                // Now it is safe to start animations
                // The view is properly attached to the window
            }
            
            override fun onViewDetachedFromWindow(v: View) {
                Log.d(TAG, "Nutrient component detached: ${v.javaClass.simpleName}")
                // Cancel any ongoing animations to prevent crashes
                cancelAllAnimations(v)
            }
        })
        
        // Mark that listener has been added to prevent duplicates
        view.setTag(R.id.attach_state_listener_added, true)
    }
    
    /**
     * Cancels all animations on a view to prevent detached view crashes
     */
    private fun cancelAllAnimations(view: View) {
        try {
            // Cancel view animations
            view.clearAnimation()
            
            // Cancel property animators
            view.animate().cancel()
            
            // Cancel any running animators
            view.animate().setDuration(0).alpha(1f).scaleX(1f).scaleY(1f).cancel()
            
        } catch (e: Exception) {
            Log.w(TAG, "Error canceling animations: ${e.message}")
        }
    }
} 