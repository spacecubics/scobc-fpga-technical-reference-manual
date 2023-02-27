MANUAL := SpaceCubics_OBC_FPGA_Technical_Reference_Manual_revx

all: ${MANUAL}.docx

${MANUAL}.docx: *.org template/sc_pandoc_trm_reference.docx images/*.png
	pandoc --toc --reference-doc template/sc_pandoc_trm_reference.docx \
	technical_reference_manual.org \
	overview.org \
	memory_map.org \
	interrupt.org \
	system_register.org \
	system_monitor.org \
	general_purpose_timer.org \
	hrmem.org \
	qspi_controller.org \
	can_controller.org \
	ahb_uart_lite.org \
	i2c_master_controller.org \
	revision_history.org \
	-o $@

clean:
	${RM} *.docx *.pdf
