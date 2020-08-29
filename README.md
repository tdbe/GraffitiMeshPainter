Unity tool that uses RWStructuredBuffers and RenderTextures and an atlasser to paint on any type mesh using a SDF brush, in the same material as the one that renders normally to the screen.

2019:

//- Painting works with volumetric "brush" or "knife blade" that goes in world space piercing the mesh including back side, on animated skinned meshes, with shading, with casting of shadows, double sided, with multiple lights, with tessellation, with subsurface scattering and (all uber features except parallax, or rather parallax doesn't support height from paint). It also shows a projected layer of brush shape/color (and color picker but that's off). It uses a Render Textures as an atlas, with R/W i/o shader model 5 registers.

//- I used Uber instead of standard shader. Inserted my code as functions and identifiable parameters inside a fork of the uber cginc. Then referenced them from a fork of the tessellated metallic core uber shader. Uses 3 more passes before the forward base pass. (2x forward base passes, and color mask 0 pass).
Also refactored the app architecture to abstract away the input from the painter tools, so you can customize their parameters and also assign their input to any controller.