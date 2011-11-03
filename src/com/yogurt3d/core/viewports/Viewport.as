/*
 * Viewport.as
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
 
 
package com.yogurt3d.core.viewports {
	import com.yogurt3d.Yogurt3D;
	import com.yogurt3d.core.cameras.interfaces.ICamera;
	import com.yogurt3d.core.managers.idmanager.IDManager;
	import com.yogurt3d.core.managers.mousemanager.PickManager;
	import com.yogurt3d.core.namespaces.YOGURT3D_INTERNAL;
	import com.yogurt3d.core.objects.interfaces.IEngineObject;
	import com.yogurt3d.core.sceneobjects.interfaces.IScene;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	/**
	 * 
	 * 
 	 * @author Yogurt3D Engine Core Team
 	 * @company Yogurt3D Corp.
 	 **/
	public class Viewport extends Sprite implements IEngineObject{	
		
		use namespace YOGURT3D_INTERNAL;
		
		private static var viewports:Vector.<uint> = Vector.<uint>([0,1,2]);
		
		private var m_viewportID				: uint;
		
		private var m_width 					: Number;
		private var m_height 					: Number;
		private var m_matrix 					: Matrix3D;
		
		private var m_viewportLayers 			: Vector.<ViewportLayer>;
		
		private var m_layerDepthByViewportLayer	: Dictionary;
		
		private var m_pickingEnabled			: Boolean;
		
		private var m_pickManager				:PickManager;
		
		private var m_antiAliasing				: uint = ViewportAntialiasing.HIGH_ALIASING;
		
		private var m_context:Context3D;
		/**
		 * 
		 * @param enableMouseManager
		 * 
		 */
		public function Viewport(enablePicking:Boolean = false) {
			super();
			
			initInternals(enablePicking);		
			trackObject();
		}

		public function get antiAliasing():uint
		{
			return m_antiAliasing;
		}

		public function set antiAliasing(value:uint):void
		{
			if( value != m_antiAliasing )
			{
				m_antiAliasing = value;
				
				if( !(m_width == 0 || m_height == 0) )
					m_context.configureBackBuffer(m_width, m_height, m_antiAliasing,true);
			}
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public function get systemID() : String {
			return IDManager.getSystemIDByObject(this);
		}

		/**
		 * 
		 * @return 
		 * 
		 */
		public function get userID() : String {
			return IDManager.getUserIDByObject(this);
		}

		/**
		 * @private 
		 * @param _value
		 * 
		 */
		public function set userID(_value : String) : void {
			IDManager.setUserIDByObject(_value, this);
		}

		/**
		 * 
		 * @return 
		 * 
		 */
		public function get matrix() : Matrix3D {
			return m_matrix;
		}



		/**
		 * 
		 * 
		 */
		public function dispose() : void {
			IDManager.removeObject(this);
			
			m_context = null;
			
			viewports.push( m_viewportID  );
		}
		
		/**
		 * 
		 * @param _x
		 * @param _y
		 * @param _width
		 * @param _height
		 * 
		 */
		public function setViewport( _x : int, _y : int, _width : int, _height : int ) : void {	
			super.x = _x;
			super.y = _y;
			
			var point:Point = new Point( _x, _y );
			point = localToGlobal( point );
			
			if( _width > 2048 )
			{
				_width = 2048;
			}
			if( _height > 2048 )
			{
				_height = 2048;
			}
			
			m_width = _width;
			m_height = _height;
			
			
			graphics.clear();
			if( m_viewportID == 0 )
			{
				graphics.beginFill(0x00FF00, 0 );
			}else{
				graphics.beginFill(0xFF0000, 0 );
			}
			graphics.drawRect( 0,0, _width, _height );
			graphics.endFill();
			
			
			Y3DCONFIG::TRACE
			{
				trace("[Viewport "+m_viewportID+"] x: ", point.x, "y: ", point.y, "width: ", _width, "height: ", _height);
			}
			
			Yogurt3D.STAGE.stage3Ds[m_viewportID].x = point.x;
			Yogurt3D.STAGE.stage3Ds[m_viewportID].y = point.y;

			if( !(_width == 0 || _height == 0) )
				m_context.configureBackBuffer(_width, _height, m_antiAliasing,true);
			
			
			m_matrix = new Matrix3D(Vector.<Number>([
				_width / 2, 0, 0, 0,
				0,  -_height / 2, 0, 0,
				0,  0, 1, 0,
				_x + _width / 2, _y + _height / 2, 0, 1]));
		}
		
		public function setBackBuffer( _width:uint, _height:uint ):void{
			if( !(_width == 0 || _height == 0) )
				m_context.configureBackBuffer(_width, _height, m_antiAliasing,true);
		}
		
		/*public override function set visible(value:Boolean):void{
			super.visible = value;
			Yogurt3D.STAGE.stage3Ds[m_viewportID].visible = value;
		}*/

		/**
		 * 
		 * @param _value
		 * 
		 */
		override public function set x(_value : Number) : void {

			setViewport(_value, y, m_width, m_height);

		}

		/**
		 * 
		 * @param _value
		 * 
		 */
		override public function set y(_value : Number) : void {
			setViewport(x, _value, m_width, m_height);

		}

		/**
		 * 
		 * @return 
		 * 
		 */
		override public function get width() : Number {
			return m_width;
		}
		/**
		 * @private
		 * @param value
		 * 
		 */
		override public function set width(value : Number) : void {
			setViewport(x, y, value, m_height);
		}
		/**
		 * 
		 * @return 
		 * 
		 */
		override public function get height() : Number {
			return m_height;
		}

		/**
		 * @private  
		 * @param value
		 * 
		 */
		override public function set height(value : Number) : void {
			setViewport(x, y, m_width, value);
		}

		/**
		 * @inheritDoc   
		 * @param _enableMouseManager
		 * 
		 */
		protected function initInternals(_enableMouseManager:Boolean = false) : void {
			
			if( viewports.length > 0 )
			{
				m_viewportID = viewports.shift();
				m_context = Yogurt3D.CONTEXT3D[m_viewportID];
				
				Y3DCONFIG::RELEASE
				{
					m_context.enableErrorChecking = false;
				}
				Y3DCONFIG::DEBUG
				{
					m_context.enableErrorChecking = true;
				}
				Y3DCONFIG::TRACE
				{
					trace("Y3D Driver:", m_context.driverInfo);
				}
			}else{
				throw new Error("Maximum 3 viewports are supported. You must dispose before creating a new one.");
			}
			
			if (_enableMouseManager) {
				m_pickManager = new PickManager( this );
			}
			
		}

		protected function trackObject() : void {
			IDManager.trackObject(this, Viewport);
		}
		
		override public function toString():String{
			return "[Viewport "+ m_viewportID +"]{x:"+ x +",y:"+ y +",width:"+ width +",height:"+ height +"}";
		}

		public function renew() : void {
		}

		/**
		 * Not Implemented 
		 * @return 
		 * 
		 */		
		public function instance():*
		{
			throw new Error("Instantiating of this object is not supported");
		}
		
		public function clone() : IEngineObject {
			throw new Error("Cloning of this object is not supported");
		}

		public function get context3d():Context3D
		{
			return m_context;
		}

		public function set context3d(value:Context3D):void
		{
			m_context = value;
		}

		public function get pickingEnabled():Boolean
		{
			return m_pickingEnabled;
		}

		public function set pickingEnabled(value:Boolean):void
		{
			
			m_pickingEnabled = value;
			if( value )
			{
				m_pickManager = new PickManager( this );
			}else{
				if( m_pickManager )
				{
					m_pickManager.dispose();
				}
				m_pickManager = null;
			}
			
		}
		
		public function update( _scene:IScene ):void{
			if( m_pickManager )
			{
				m_pickManager.update( _scene, _scene.activeCamera );
			}
		}
		

	}
}
