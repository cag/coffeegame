define ['./cg'],
  (cg) ->
    {input, audio, util, game, geometry, entity, physics} = cg

    right_to_left = true

    default_style =
        fontSize: 10
        font: 'sans-serif'
        lineStyles: 'white black 1.0 round round'
        fillStyle: 'rgb(26,47,158)'

    wordWrapText = (text, width, style, context) ->
        wordWrapLine = (line) ->
            word_delimeter = ' '
            words = line.split word_delimeter
            lines = []
            current_line = ''
            for word, i in words
                current_line_candidate = if i is 0 then word else current_line + word_delimeter + word
                if (context.measureText current_line_candidate).width > width
                    lines.push current_line
                    current_line = word
                else
                    current_line = current_line_candidate
            lines.push current_line if current_line isnt ''
            return lines
        line_delimeter = '\n'
        style = style or default_style
        context = context or game.canvas().getContext '2d'
        context.save()
        context.font = style.fontSize + 'px ' + style.font
        lines = [].concat (wordWrapLine line for line in text.split line_delimeter)...
        context.restore()
        return lines

    drawTextBox = (x, y, width, height, lines_scrolled, text_obj, style, context) ->
        style = style or default_style
        context = context or game.canvas().getContext '2d'

        context.save()

        context.font = style.font
        context.textBaseline = "top"
        [
            mainLineStrokeStyle
            context.strokeStyle
            context.lineWidth
            context.lineCap
            context.lineJoin
        ] = style.lineStyles.split ' '
        context.fillStyle = style.fillStyle

        context.fillRect(x + 1.0, y + 1.0, width - 2.0, height - 2.0)
        context.strokeRect(x + 1.5, y + 1.5, width - 2.0, height - 2.0)
        context.strokeStyle = mainLineStrokeStyle
        context.strokeRect(x + 0.5, y + 0.5, width - 2.0, height - 2.0)

        context.beginPath()
        context.rect x + 2.0, y + 2.0, width - 4.0, height - 4.0
        context.clip()
        context.fillStyle = mainLineStrokeStyle
        context.textAlign = 'start'
        for line, i in text_obj.lines
            if right_to_left
                context.fillText line, x + width - 3.0, y + 3.0 + (i-lines_scrolled)*text_obj.spacing
            else
                context.fillText line, x + 3.0, y + 3.0 + (i-lines_scrolled)*text_obj.spacing

        context.restore()
        return

    isRightToLeft: -> right_to_left

    textBoxDialog: (text, x, y, width, height, speed, style, context, callback) ->
        game.state = 'dialog'
        style = style or default_style
        context = context or game.canvas().getContext '2d'
        line_progress = 0.0
        lines_scrolled = 0.0
        num_lines_per_screen = ((height - 6.0) / style.fontSize) | 0
        cur_line_idx = 0
        cur_line = ''
        word_wrapped_text = wordWrapText text, width-6, style, context
        displayed_text = []
        done = false
        updateGenerator = ->
            while cur_line_idx < word_wrapped_text.length
                dt = yield undefined
                delta = dt * speed * (if input.jump.state then 3.0 else 1.0)
                if lines_scrolled >= cur_line_idx - num_lines_per_screen + 1
                    new_line_progress = line_progress + delta
                else
                    lines_scrolled = Math.min cur_line_idx - num_lines_per_screen + 1, lines_scrolled + delta
                if new_line_progress | 0 > line_progress | 0
                    if new_line_progress >= word_wrapped_text[cur_line_idx].length
                        cur_line_idx++
                        cur_line = ''
                        line_progress = 0.0
                        new_line_progress = 0.0
                        displayed_text = word_wrapped_text[...cur_line_idx]
                    else
                        cur_line = word_wrapped_text[cur_line_idx][...(new_line_progress | 0)].trim()

                    displayed_text[cur_line_idx] = cur_line
                line_progress = new_line_progress
                # if input.debug.pressed
                #     console.log {
                #         num_lines_per_screen: num_lines_per_screen
                #         line_progress: line_progress
                #         lines_scrolled: lines_scrolled
                #         cur_line_idx: cur_line_idx
                #         cur_line: cur_line
                #         word_wrapped_text: word_wrapped_text
                #         displayed_text: displayed_text
                #     }
            displayed_text = word_wrapped_text
            dt = yield undefined until input.jump.pressed
            done = true
            callback?()
        drawGenerator = ->
            until done
                context = yield undefined
                drawTextBox x, y, width, height, lines_scrolled, {
                        spacing: style.fontSize
                        lines: displayed_text
                    }, style, context

        game.invoke util.prepareCoroutineSet updateGenerator, drawGenerator
