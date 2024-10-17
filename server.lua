addEventHandler( "onPlayerWasted", root,
	function()
		removePedFromVehicle(source)  
	end
)

function displayVehicleLoss(loss)
    if getElementHealth(source) < 300 then
		cancelEvent();
		setElementHealth(source, 300)
	end
end
addEventHandler("onVehicleDamage", root, displayVehicleLoss)