###
Copyright (c) 2012 [DeftJS Framework Contributors](http://deftjs.org)
Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
###

Ext.define( 'Deft.util.Deferred',
	alternateClassName: [ 'Deft.Deferred' ]
	
	constructor: ->
		@state = 'pending'
		@progress = undefined
		@value = undefined
		
		@progressCallbacks = []
		@successCallbacks  = []
		@failureCallbacks  = []
		@cancelCallbacks   = []
		
		@promise = Ext.create( 'Deft.Promise', @ )
		
		return @
	
	###*
	Returns a new {@link Deft.util.Promise} with the specified callbacks registered to be called when this {@link Deft.util.Deferred} is resolved, rejected, updated or cancelled.
	###
	then: ( callbacks ) ->
		if Ext.isObject( callbacks )
			{ success: successCallback, failure: failureCallback, progress: progressCallback, cancel: cancelCallback } = callbacks
		else
			[ successCallback, failureCallback, progressCallback, cancelCallback ] = arguments
		
		for callback in [ successCallback, failureCallback, progressCallback, cancelCallback ]
			if not ( Ext.isFunction( callback ) or callback is null or callback is undefined )
				Ext.Error.raise( 'Error while configuring callback: a non-function specified.' )
		
		deferred = Ext.create( 'Deft.Deferred' )
		
		wrapCallback = ( callback, action ) ->
			return ( value ) ->
				if Ext.isFunction( callback )
					try
						result = callback( value )
						if result is undefined
							deferred[ action ]( value )
						else if result instanceof Ext.ClassManager.get( 'Deft.util.Promise' ) or result instanceof Ext.ClassManager.get( 'Deft.util.Deferred' )
							result.then( Ext.bind( deferred.resolve, deferred ), Ext.bind( deferred.reject, deferred ), Ext.bind( deferred.update, deferred ), Ext.bind( deferred.cancel, deferred ) )
						else
							deferred.resolve( result )
					catch error
						deferred.reject( error )
				else
					deferred[ action ]( value )
				return
		
		
		@register( wrapCallback( successCallback, 'resolve' ), @successCallbacks, 'resolved',  @value )
		@register( wrapCallback( failureCallback, 'reject'  ), @failureCallbacks, 'rejected',  @value )
		@register( wrapCallback( cancelCallback,  'cancel'  ), @cancelCallbacks,  'cancelled', @value )
		
		wrapProgressCallback = ( callback ) ->
			return ( value ) ->
				if Ext.isFunction( callback )
					result = callback( value )
					if result is undefined
						deferred.update( value )
					else
						deferred.update( result )
				else
					deferred.update( value )
				return
		
		@register( wrapProgressCallback( progressCallback ), @progressCallbacks, 'pending', @progress )
		
		return deferred.getPromise()
	
	###*
	Returns a new {@link Deft.util.Promise} with the specified callbacks registered to be called when this {@link Deft.util.Deferred} is either resolved, rejected, or cancelled.
	###
	always: ( alwaysCallback ) ->
		return @then( 
			success: alwaysCallback
			failure: alwaysCallback
			cancel: alwaysCallback
		)
	
	###*
	Update progress for this {@link Deft.util.Deferred} and notify relevant callbacks.
	###
	update: ( progress ) ->
		if @state is 'pending'
			@progress = progress
			@notify( @progressCallbacks, progress )
		else
			Ext.Error.raise( 'Error: this Deferred has already been completed and cannot be modified.')
		return
	
	###*
	Resolve this {@link Deft.util.Deferred} and notify relevant callbacks.
	###
	resolve: ( value ) ->
		@complete( 'resolved', value, @successCallbacks )
		return
	
	###*
	Reject this {@link Deft.util.Deferred} and notify relevant callbacks.
	###
	reject: ( error ) ->
		@complete( 'rejected', error, @failureCallbacks )
		return
	
	###*
	Cancel this {@link Deft.util.Deferred} and notify relevant callbacks.
	###
	cancel: ( reason ) ->
		@complete( 'cancelled', reason, @cancelCallbacks )
		return
	
	###*
	Get this {@link Deft.util.Deferred}'s associated {@link Deft.util.Promise}.
	###
	getPromise: ->
		return @promise
	
	###*
	Get this {@link Deft.util.Deferred}'s current state.
	###
	getState: ->
		return @state
	
	###*
	Register a callback for this {@link Deft.util.Deferred} for the specified callbacks and state, immediately notifying with the specified value (if applicable).
	@private
	###
	register: ( callback, callbacks, state, value ) ->
		if Ext.isFunction( callback )
			if @state is 'pending'
				callbacks.push( callback )
			if @state is state and value isnt undefined
				@notify( [ callback ], value )
		return
	
	###*
	Complete this {@link Deft.util.Deferred} with the specified state and value.
	@private
	###
	complete: ( state, value, callbacks ) ->
		if @state is 'pending'
			@state = state
			@value = value
			@notify( callbacks, value )
			@releaseCallbacks()
		else
			Ext.Error.raise( 'Error: this Deferred has already been completed and cannot be modified.')
		return
	
	###*
	@private
	Notify the specified callbacks with the specified value.
	###
	notify: ( callbacks, value ) ->
		for callback in callbacks
			callback( value )
		return
	
	###*
	@private
	Release references to all callbacks registered with this {@link Deft.util.Deferred}.
	###
	releaseCallbacks: ->
		@progressCallbacks = null
		@successCallbacks  = null
		@failureCallbacks  = null
		@cancelCallbacks   = null
		return
	
)