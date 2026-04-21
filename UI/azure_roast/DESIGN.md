# Design System Documentation: Hulu Coffee Mobile POS

## 1. Overview & Creative North Star
**Creative North Star: "Artisanal Logic"**

In the fast-paced world of coffee service, the interface must be as precise as a scale and as inviting as a fresh roast. This design system rejects the "SaaS-template" aesthetic in favor of a high-end editorial experience. We bridge the gap between **Blue Finance** (the reliability of a banking app) and **Premium Coffee** (the warmth of a boutique café).

To achieve this, we break the grid through **intentional asymmetry** and **tonal depth**. We move away from rigid lines and instead use "breathing room" and layered surfaces to guide the barista’s eye. The goal is a POS that feels less like a tool and more like a digital extension of the craft.

---

## 2. Color Philosophy
Our palette is anchored in deep, authoritative blues (`primary`) to instill trust in financial transactions, complemented by the organic warmth of coffee-inspired tones (`secondary` and `tertiary`).

### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid borders for sectioning. 
Boundaries must be defined solely through background color shifts. For example, a product grid sitting on `surface-container-low` achieves its boundary naturally against the `surface` background. If you feel the need to draw a line, instead, use a shift in tonal value.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of premium materials.
- **Base Layer:** `surface` (The canvas).
- **Secondary Grouping:** `surface-container-low` (Defining a sidebar or a cart area).
- **Interactive Elements:** `surface-container-lowest` (The "white paper" cards that hold individual orders).
Each inner container must use a slightly higher or lower tier to define its importance, creating a "nested" depth that feels tactile.

### The "Glass & Gradient" Rule
To elevate the POS beyond a standard utility, use **Glassmorphism** for floating elements (like a "Current Total" bar). Apply `surface-container-lowest` at 80% opacity with a `backdrop-blur` of 20px. 
**Signature Textures:** Use subtle linear gradients for primary CTAs, transitioning from `primary` (#003466) to `primary-container` (#1a4b84) at a 135-degree angle. This adds "soul" and a professional shimmer that flat colors cannot replicate.

---

## 3. Typography
We use a dual-typeface strategy to balance character with utility.

*   **Display & Headlines (Manrope):** A modern, geometric sans-serif. Used for "The Big Numbers"—order totals, hero product names, and section titles. It carries the "Modern" brand personality.
*   **Body & Labels (Inter):** A workhorse for fast-paced environments. Its high x-height ensures readability even when the tablet is at an arm's length on a counter.

**Hierarchy as Identity:**
- **The Editorial Hook:** Use `display-lg` for the final checkout amount to make the transaction feel significant.
- **The Micro-Detail:** Use `label-md` in uppercase with 0.05em letter spacing for "Status" or "Category" tags to evoke a premium receipt aesthetic.

---

## 4. Elevation & Depth
Hierarchy is achieved through **Tonal Layering** rather than structural scaffolding.

*   **The Layering Principle:** Depth is "stacked." Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift. 
*   **Ambient Shadows:** For floating modals or "Pay" buttons, use shadows that are extra-diffused. 
    *   *Shadow Color:* Tint the shadow with `on-surface` at 6% opacity.
    *   *Blur:* 24px to 32px.
    *   *Offset:* 8px downward.
*   **The "Ghost Border" Fallback:** If a border is essential for accessibility, it must be a **Ghost Border**: use the `outline-variant` token at **15% opacity**. Never use 100% opaque borders.
*   **Integrated Glass:** By using backdrop blurs on the cart summary, we allow the product images to softly bleed through, making the layout feel like one cohesive, high-end environment rather than disconnected boxes.

---

## 5. Components

### Buttons
*   **Primary:** Gradient-filled (`primary` to `primary-container`) with `xl` (3rem) roundedness. No border. Text is `on-primary`.
*   **Secondary:** `surface-container-high` background with `on-surface` text. These should feel like they are "etched" into the surface.
*   **States:** On press, reduce the scale to 0.98 and increase the `surface-tint` overlay by 10%.

### Cards (Product/Order)
*   **Style:** `surface-container-lowest` background with `DEFAULT` (1rem) corner radius. 
*   **Spacing:** Minimum 16px internal padding.
*   **Forbid Dividers:** Do not use lines between line items in a cart. Use `8px` of vertical white space and a 2-step font size difference between the item name (`title-md`) and the modifiers (`body-sm`).

### Input Fields
*   **Style:** Unfilled, "Ghost" style. Use a `surface-variant` background with a `sm` (0.5rem) corner radius.
*   **Focus State:** Transition the background to `primary-fixed` and change the text color to `on-primary-fixed`. No focus rings; use a subtle background color shift.

### Chips (Drink Modifiers)
*   **Action Chips:** `secondary-container` background with `on-secondary-container` text. These add the "Coffee Accent" to the UI, highlighting special requests like "Oat Milk" or "Extra Shot."

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts in the product grid (e.g., one large "Daily Special" card next to two smaller cards).
*   **Do** prioritize white space over information density. A premium coffee experience should never feel cluttered.
*   **Do** use `tertiary` (#492d19) for "Warning" or "Alert" states instead of harsh reds when the context allows (e.g., "Out of Stock").

### Don't
*   **Don't** use 1px dividers. If you need separation, use a 4px gap of the `surface` background color.
*   **Don't** use pure black (#000000). Use `on-surface` (#1a1c1d) to maintain the soft, professional tone.
*   **Don't** use sharp corners. Everything in the Hulu system should feel approachable and "hand-finished"—maintain a 16px minimum radius on all cards.
*   **Don't** use standard drop-shadows. Shadows must be low-contrast and color-tinted to avoid looking "dirty."