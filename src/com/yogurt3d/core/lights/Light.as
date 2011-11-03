/*
* Light.as
* This file is part of Yogurt3D Flash Rendering Engine 
*
* Copyright (C) 2011 - Yogurt3D Corp.
*
* Yogurt3D Flash Rendering Engine is free software; you can redistribute it and/or
* modify it under the terms of the YOGURT3D CLICK-THROUGH AGREEMENT
* License.
* 
* Yogurt3D Flash Rendering Engine is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
* 
* You should have received a copy of the YOGURT3D CLICK-THROUGH AGREEMENT
* License along with this library. If not, see <http://www.yogurt3d.com/yogurt3d/downloads/yogurt3d-click-through-agreement.html>. 
*/


package com.yogurt3d.core.lights
{
	import com.yogurt3d.core.geoms.SkeletalAnimatedMesh;
	import com.yogurt3d.core.geoms.SkinnedSubMesh;
	import com.yogurt3d.core.geoms.interfaces.IMesh;
	import com.yogurt3d.core.helpers.ProjectionUtils;
	import com.yogurt3d.core.managers.vbstream.VertexStreamManager;
	import com.yogurt3d.core.materials.base.Color;
	import com.yogurt3d.core.materials.shaders.ShaderDepthMap;
	import com.yogurt3d.core.namespaces.YOGURT3D_INTERNAL;
	import com.yogurt3d.core.sceneobjects.Scene;
	import com.yogurt3d.core.sceneobjects.SceneObjectContainer;
	import com.yogurt3d.core.sceneobjects.interfaces.ISceneObjectRenderable;
	import com.yogurt3d.core.sceneobjects.interfaces.ISelfRenderable;
	import com.yogurt3d.core.texture.RenderTextureTarget;
	import com.yogurt3d.core.transformations.Transformation;
	import com.yogurt3d.core.utils.MatrixUtils;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace YOGURT3D_INTERNAL;
	
	/**
	 * This class is a scene object representing a light. It is not visible but it effect the rendering process.<br/>
	 * 
	 * @author Yogurt3D Engine Core Team
	 * @company Yogurt3D Corp.
	 **/
	public class Light extends SceneObjectContainer
	{		
		private static var m_depthProgram:ShaderDepthMap;
		
		private var m_color				:Color;		
		
		private var m_type				:ELightType;
		
		private var m_direction			:Vector3D;
		private var m_attenuation		:Vector.<Number>;

		private var m_range             :Number;
		
		private var m_castShadows		:Boolean					= false;
		private var m_shadowMap			:RenderTextureTarget;
		private var m_shadowMap2		:RenderTextureTarget;
		private var m_shadowColor		:Color;
		
		private var m_isFilteringOn      :Boolean                  = true;
		
		
		
		private var m_innerConeAngle	: Number;
		private var m_outerConeAngle	: Number;
		private var m_coneAngles		: Vector.<Number>;
		
		YOGURT3D_INTERNAL var m_projectionMatrix		:Matrix3D;
		
		/**
		 * 
		 * @param _type
		 * @param _color
		 * @param _intensity
		 * 
		 */
		public function Light(_type:ELightType = null, _color:uint = 0xFFFFFF, _intensity:Number=1)
		{
			m_type 	= _type;
			
			if( m_type == null )
			{
				m_type = ELightType.POINT;
			}
			m_attenuation = new Vector.<Number>(4,true);
			m_attenuation[0] = 1;
			m_attenuation[1] = 0;
			m_attenuation[2] = 0;
			m_attenuation[3] = 1;
			
			m_innerConeAngle = 20;
			m_outerConeAngle = 30;
			
			m_coneAngles = new Vector.<Number>(4,true);
			m_coneAngles[0] = m_innerConeAngle;
			m_coneAngles[1] = m_outerConeAngle;
			
			innerConeAngle = 40;
			outerConeAngle = 60;
			m_range = 150;
			
			m_color = new Color(0,0,0);
			m_color.setColorUint( 0xFF000000 | _color );
			
			m_shadowColor = new Color(0,0,0,1);
			
			m_direction = new Vector3D();
			intensity = _intensity;
			
			setProjection();			
		}
		
		/**
		 * Changes shadow color and alpha
		 * @return 
		 * 
		 */		
		public function get shadowColor():Color
		{
			return m_shadowColor;
		}

		/**
		 * @private
		 */
		public function set shadowColor(value:Color):void
		{
			if( value != null )
			{
				m_shadowColor = value;
			}
		}

		public function get color():Color{
			return m_color;
		}
		
		public function set color( _color:Color):void
		{
			if( _color != null )
			{
				m_color = _color;
			}
		}
		
		public function get isFilteringOn():Boolean
		{
			return m_isFilteringOn;
		}
		
		public function set isFilteringOn(_value:Boolean):void
		{
			m_isFilteringOn = _value;
		}
		
		public function get range():Number{
			return m_range;
		}
		
		public function set range( _range:Number):void
		{
			m_range = _range;
			//setProjection();
		}
		/**
		 * @inheritDoc   
		 * @return 
		 * @default perspective projection with 45 fovy, 4/3 aspect ratio, near plane at 1 and far plane at 500
		 */
		public function get projectionMatrix():Matrix3D
		{
			return m_projectionMatrix;
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public function get castShadows():Boolean
		{
			return m_castShadows;
		}
		/**
		 * @private 
		 * @param value
		 * 
		 */		
		public function set castShadows(value:Boolean):void
		{
			m_castShadows = value;
		}
		/**
		 * @inheritDoc
		 */
		public function get type():ELightType
		{
			return m_type;
		}
		/**
		 * @private 
		 * @param value
		 * 
		 */		
		public function set type(value:ELightType):void
		{
			m_type = value;
			
			if( m_shadowMap )
			{
				m_shadowMap.dispose();
				m_shadowMap = null;
			}
			
			if( m_shadowMap2 )
			{
				m_shadowMap2.dispose();
				m_shadowMap2 = null;
			}
			
			setProjection();
		}
		/**
		 * @inheritDoc
		 * 
		 */		
		public function get attenuation():Vector.<Number>{
			return m_attenuation;
		}
		
		public function set attenuation( _val:Vector.<Number>):void{
			m_attenuation = _val;
		}
		
		/**
		 * @inheritDoc
		 * @default 0.8 (36 degrees)
		 */		
		public function get innerConeAngle():Number{
			
			return m_innerConeAngle * 2;
		}
		
		public function set innerConeAngle( _val:Number):void{
			m_innerConeAngle = _val / 2;
			m_coneAngles[0] = Math.cos(m_innerConeAngle*Transformation.DEG_TO_RAD);
			m_coneAngles[2] = 1 /  m_coneAngles[0] - m_coneAngles[1];
		}
		/**
		 * @inheritDoc
		 * @default 0.8 (36 degrees)
		 */		
		public function get outerConeAngle():Number{
			
			return m_outerConeAngle * 2;
		}
		
		public function set outerConeAngle( _val:Number):void{
			m_outerConeAngle = _val / 2;
			m_coneAngles[1] = Math.cos(m_outerConeAngle*Transformation.DEG_TO_RAD);
			m_coneAngles[2] = 1 / (m_coneAngles[0] - m_coneAngles[1]);
			
			setProjection();
		}
		/**
		 * Intensity of the light. Allowed values are between 0-1, from dark to light sequentially. 
		 * @return Intensity of the light source.
		 * 
		 */		
		public function get intensity():Number
		{
			return m_color.a;
		}
		/**
		 * @private 
		 * @param value
		 * 
		 */		
		public function set intensity(value:Number):void
		{
			m_color.a  = value;
		}
		/**
		 * @inheritDoc
		 * 
		 */		
		public function get positionVector():Vector.<Number> 
		{
			var _pos:Vector3D = transformation.globalPosition;
			return Vector.<Number>([_pos.x, _pos.y, _pos.z, 1]);
		}
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get directionVector():Vector.<Number>
		{
			var _dir:Vector3D = transformation.matrixGlobal.deltaTransformVector( new Vector3D(0,0,-1,1) );
			_dir.negate();
			_dir.normalize();
			
			
			return Vector.<Number>([_dir.x, _dir.y, _dir.z, 1]);
		}
		/**
		 * @inheritDoc
		 * 
		 * @return 
		 * 
		 */
		public function get shadowMap():RenderTextureTarget
		{
			if(!m_shadowMap)
			{
				m_shadowMap = new RenderTextureTarget(1024,1024);
			}
			return m_shadowMap;
		}
		
		public function get shadowMap2():RenderTextureTarget
		{
			if(!m_shadowMap2 && m_type == ELightType.POINT )
			{
				m_shadowMap2 = new RenderTextureTarget(1024,1024);
			}
			return m_shadowMap2;
		}
		
		
		/**
		 * @private
		 * @param value
		 * 
		 */
		public function set shadowMap(value:RenderTextureTarget):void
		{
			m_shadowMap = value;
		}
		
		public function set shadowMap2(value:RenderTextureTarget):void
		{
			m_shadowMap2 = value;
		}
		
		/**
		 * @inheritDoc  
		 * @param _width
		 * @param _height
		 * @param _near
		 * @param _far
		 * 
		 */		
		public function setProjectionOrtho(_width:Number, _height:Number, _near:Number, _far:Number):void
		{		
			m_projectionMatrix = ProjectionUtils.setProjectionOrtho( _width, _height, _near, _far );
		}
		/**
		 * @inheritDoc   
		 * @param _left
		 * @param _right
		 * @param _bottom
		 * @param _top
		 * @param _near
		 * @param _far
		 * 
		 */		
		public function setProjectionOrthoAsymmetric(_left:Number, _right:Number, _bottom:Number, _top:Number, _near:Number, _far:Number):void
		{
			m_projectionMatrix = ProjectionUtils.setProjectionOrthoAsymmetric(_left, _right, _bottom, _top, _near, _far);
		}
		/**
		 * @inheritDoc   
		 * @param _fovy
		 * @param _aspect
		 * @param _near
		 * @param _far
		 * 
		 */		
		public function setProjectionPerspective(_fovy:Number, _aspect:Number, _near:Number, _far:Number):void
		{	
			m_projectionMatrix = ProjectionUtils.setProjectionPerspective(_fovy, _aspect, _near, _far);
		}
		/**
		 * @inheritDoc   
		 * @param _left
		 * @param _right
		 * @param _bottom
		 * @param _top
		 * @param _near
		 * @param _far
		 * 
		 */		
		public function setProjectionPerspectiveAsymmetric(_width:Number, _height:Number,  _near:Number, _far:Number):void
		{
			
			m_projectionMatrix = ProjectionUtils.setProjectionPerspectiveAsymmetric(_width, _height, _near, _far);
		}
		
		/**
		 * sets the projection matrix of the light according to light type and the outer angle 
		 * is used for shadow map generation
		 */
		public function setProjection():void{
			if (m_type == ELightType.SPOT){
				setProjectionPerspective( outerConeAngle, 1.0, 5, 10000.0 );
			}else if( m_type == ELightType.DIRECTIONAL && scene) {
				var temp:Matrix3D = MatrixUtils.TEMP_MATRIX;
				temp.copyFrom( transformation.matrixGlobal );
				temp.position = new Vector3D(0,0,0);
				temp.invert();
				
				//var _x :Vector.<Number> = this.directionVector;
				
				var _min :Vector3D = new Vector3D(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
				var _max :Vector3D = new Vector3D(Number.MIN_VALUE, Number.MIN_VALUE, Number.MIN_VALUE);
				var corner:Vector3D;

				var corners:Vector.<Vector3D> = Scene(scene).m_rootObject.axisAlignedBoundingBox.corners;
				
				for(var i:int = 0 ; i < 8; i++)
				{
					corner = temp.transformVector(corners[i]);
					
					if(corner.x > _max.x) _max.x = corner.x;
					if(corner.x < _min.x) _min.x = corner.x;
					if(corner.y > _max.y) _max.y = corner.y;
					if(corner.y < _min.y) _min.y = corner.y;
					if(corner.z > _max.z) _max.z = corner.z;
					if(corner.z < _min.z) _min.z = corner.z;
					
				}
				setProjectionOrthoAsymmetric(_min.x, _max.x, _min.y, _max.y, -_max.z, -_min.z );
			}
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */		
		override protected function initInternals():void
		{
			super.initInternals();
			
			m_projectionMatrix			= new Matrix3D();
		}
		/**
		 * @inheritDoc 
		 * @return 
		 * 
		 */		
		public override function toString():String{
			return "[Light (type:" + m_type + ", id:"+super.toString()+", position:"+positionVector+", direction:"+directionVector+")]";
		}
		
		public function get coneAngles():Vector.<Number>
		{
			m_coneAngles[3] = m_range;
			return m_coneAngles;
		}
		
		
	}
}
