---
applyTo: '**'
---
# Instructions for hardware specifications

- dht11 for just exploating the temperature and humidity on the app on the admin or even the client interface
- VL53L0X-V2 has a interesting role

its role is when a product falls after the motor pushed it
the sensor will detect the product like i have a Vending Machine Shelf as you see in the image
i will put the sensor on the side but bottom of the shelf 
so it will detect the fallen product on the range of the width of the shelf its like from 50mm to 450mm 
and when the product is detected from the sensor so in default the senor will be out of the range of 50mm to 450mm and it will be like too more than 450mm and when the product is fallen it will detect it in that range but in a ms cuz the product falls too fast like in a mili seconds 

and when it will detect it the payment will be confirmed and debited from the wallet

here is the scenario:

a client can command from the app and choose product and its quantity and then click on command and the product falls and the payment will be validated

i just think about somenthing interesting:

on the shelf i have 4 couloires for the products 
so when the client will command multi products withe multi quantity 
the sensor have to detect them all with their ranges and quantity

look how
the sensor is palced on the side like 50mm from the start of the  right side of the shelf 
and in the end in the left side it ends of 450mm 
and it has 4 couloires 
first couloir from 50mm to 150mm
2nd from 150mm to 250mm etc.....
until 
4th is from 450mm to 450mm 

so when a product is detected in the range of 250mm to 350mm, the product is on column 3 or couloir 3
and the same for quantity if the client commanded 2 prodcucts form column 3 and 3 from 1 

the sensor should detect 2 times from the range  250mm to 350mm and 3 times from 50mm to 150mm, so that the payment should be validated 

this is the role of the VL53L0X-V2 sensor:

now i will go to 4 Relay Module
the modules are the ones who will action the 4 motors of each couloir that will push the prodcuts
so each couloir has a motor and those 4 motors are powerd by those 4 modules
each motor will be powered by one module 

this is the role of the 4 Relay Module

now i will go to RFID rc522  and keypad and lcd roles:

that one is used for authenthification for a second command methode not for the default command mehtod wich is by the application 
so the second method is go authentifiacte by the rfid so each card must be linked to one account
and the command wont be by the application but with the keypad 4*4 so the client will choose the prodcut couloir from 1 to 4 and the quantity after, and the lcd will tell him first choose the row from 1 to 4 cuz each relay number or couloir will present a prodcut name and tha will be updated by the technicien that has the stock management and then the quantity so the lcd will tell the client to choose how much of the product

so this are the main functionalites of those components 


