---
title: Drifting
gdd_order: 2
scope: How the car drives, drifts and reverses, the prototypes built so far, and the research and decisions behind them.
agents_work_on: [driving-drift]
agents_read: []
---

# Drifting

## Summary

Drifting is the one core skill of Solid Carbide. The car's driving and drifting copy the board's older Unity prototype, including its drift curve and its camera, and the car can also reverse. The player drives with W to go forward, S to reverse, and A and D to steer and drift.

## Decisions

- The car's driving and drifting copy the board's Unity prototype (see Content, "Prototypes so far"). (2026-10-04)
- The car can reverse with the S key, as in the Unity prototype. Controls: W to go forward, S to reverse, A and D to steer and drift. (2026-10-04)
- The drift curve is the one the Unity prototype uses. This replaces the earlier plan to choose between three candidate curves (square root, linear or exponential) by playtesting. Drift is not meant to be realistic. (2026-10-04)
- The camera behaves like the Unity prototype's camera by default (how it follows the car, its zoom and any look-ahead), unless the board decides otherwise later. (2026-10-04)
- Settling the movement mechanics is one of the project's top priorities and the first thing to work on. (2026-10-03)

## Content

### Prototypes so far

The board built two drift prototypes before this project:

- **The older prototype, in Unity: the board is very happy with it.** It is at `C:\Users\andre\drift-to-survive` on the board's machine (Unity 6000.3, project name DriftSurvivors). The reference is its current state, with the driving values the board tuned in its pause menu, which are saved in the Windows registry rather than in the project files. Its driving and drifting are the reference for Solid Carbide. It also has reverse on the S key.
- **The newer prototype: the board is not happy with how it turned out.** It is not used as a reference and will not be analysed.

A report on how driving, drifting and reverse behave in the Unity prototype, with the preparations needed to reproduce them in Godot, is being written (task T-006). See References.

## Open questions

- Far-future idea: a trick system for the car (front flips, back flips, in the style of Olli Olli World). Long-term only.

## References

- Unity prototype report: [drifting/unity-prototype-report.md](drifting/unity-prototype-report.md) (being written in task T-006).
