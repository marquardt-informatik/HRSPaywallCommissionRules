curl -v -X POST http://10.40.97.42:7047/DynNavHRS/ws/HRS/Page/AgencyReservation -H "Content-Type: text/xml; charset=utf-8" -H "SOAPAction: urn:microsoft-dynamics-schemas/page/agencyreservation:Create" --negotiate -u : --data @soap-requests/agencyreservationRequest.xml